require 'spec_helper'
require 'timeout'

RSpec.describe RequestZipCachePath do
  subject(:cache_path) do
    described_class.new(info_request: info_request, user: user)
  end

  let(:info_request) { InfoRequest.allocate }
  let(:user) { Object.new }
  let(:version) { 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3' }

  before do
    allow(info_request).to receive(:persisted?).and_return(true)
    allow(info_request).to receive(:id).and_return(123_456)
    allow(info_request).to receive(:last_update_hash).and_return(version)
    allow(info_request).to receive(:zip_cache_file_suffix).
      with(user).and_return('')
  end

  after do
    FileUtils.rm_rf(InfoRequest.download_zip_dir)
  end

  describe '#path' do
    it 'is bounded beneath the ZIP root and keyed by the numeric request id' do
      expected = File.join(
        InfoRequest.download_zip_dir,
        'download',
        '123',
        '123456',
        version,
        'correspondence.zip'
      )

      expect(cache_path.path).to eq(expected)
      expect(File.expand_path(cache_path.path)).
        to start_with("#{File.expand_path(InfoRequest.download_zip_dir)}/")
    end

    it 'does not include a traversal-shaped URL title' do
      allow(info_request).to receive(:url_title).
        and_return('../../../../tmp/escape')

      expect(cache_path.path).not_to include('..')
      expect(cache_path.path).not_to include('escape')
    end

    it 'does not change when the URL title changes or aliases the request' do
      original_path = cache_path.path
      allow(info_request).to receive(:url_title).and_return('a-renamed-request')

      expect(
        described_class.new(info_request: info_request, user: user).path
      ).to eq(original_path)
    end

    it 'uses distinct paths for distinct authoritative request ids' do
      other_request = InfoRequest.allocate
      allow(other_request).to receive(:persisted?).and_return(true)
      allow(other_request).to receive(:id).and_return(123_457)
      allow(other_request).to receive(:last_update_hash).and_return(version)
      allow(other_request).to receive(:zip_cache_file_suffix).
        with(user).and_return('')

      other_path = described_class.new(
        info_request: other_request,
        user: user
      )

      expect(other_path.path).not_to eq(cache_path.path)
    end

    it 'preserves the visibility suffix' do
      allow(info_request).to receive(:zip_cache_file_suffix).
        with(user).and_return('_requester_only')

      expect(cache_path.path).to end_with('correspondence_requester_only.zip')
    end
  end

  describe '#write_if_missing' do
    it 'creates a new cache artifact with owner-only permissions' do
      result = cache_path.write_if_missing { |file| file.write('zip') }

      expect(result).to be(true)

      mode = File.stat(cache_path.path).mode & 0o777
      expect(mode).to eq(0o600)
      expect(File.binread(cache_path.path)).to eq('zip')
    end

    it 'does not replace an existing cache artifact' do
      cache_path.write_if_missing { |file| file.write('existing') }

      expect(cache_path.write_if_missing { |file| file.write('replacement') }).
        to be(false)
      expect(File.binread(cache_path.path)).to eq('existing')
    end

    it 'removes a partial artifact when generation fails' do
      expect {
        cache_path.write_if_missing do |file|
          file.write('partial')
          raise 'generation failed'
        end
      }.to raise_error('generation failed')

      expect(File.exist?(cache_path.path)).to be(false)
    end

    context 'with a real temporary cache directory' do
      around do |example|
        Dir.mktmpdir('request-zip-cache') do |root|
          allow(InfoRequest).to receive(:download_zip_dir).and_return(root)
          example.run
        end
      end

      it 'coordinates callers and publishes exactly one complete artifact' do
        writer_started = Queue.new
        finish_writer = Queue.new
        reader_generated = Queue.new

        writer = Thread.new do
          cache_path.write_if_missing do |file|
            file.write('partial')
            file.flush
            writer_started << true
            finish_writer.pop
            file.write('-complete')
          end
        end

        Timeout.timeout(5) { writer_started.pop }
        expect(File.exist?(cache_path.path)).to be(false)

        temporary_files = Dir.glob("#{cache_path.path}.*.part")
        expect(temporary_files.length).to eq(1)
        expect(File.stat(temporary_files.first).mode & 0o777).to eq(0o600)

        reader_path = described_class.new(
          info_request: info_request,
          user: user
        )
        reader = Thread.new do
          reader_path.write_if_missing do |file|
            reader_generated << true
            file.write('second-publication')
          end
        end

        expect(reader.join(0.1)).to be_nil
        expect(File.exist?(cache_path.path)).to be(false)

        finish_writer << true
        results = Timeout.timeout(5) { [writer.value, reader.value] }

        expect(results).to contain_exactly(true, false)
        expect(reader_generated).to be_empty
        expect(File.binread(cache_path.path)).to eq('partial-complete')
        expect(File.stat("#{cache_path.path}.lock").mode & 0o777).to eq(0o600)
        expect(Dir.glob("#{cache_path.path}.*.part")).to be_empty
      ensure
        finish_writer << true if writer&.alive?
        [writer, reader].compact.each do |thread|
          thread.join(5)
          thread.kill if thread.alive?
        end
      end

      it 'cleans a failed private artifact before another caller publishes' do
        expect {
          cache_path.write_if_missing do |file|
            file.write('partial')
            file.flush
            raise 'generation failed'
          end
        }.to raise_error('generation failed')

        expect(File.exist?(cache_path.path)).to be(false)
        expect(Dir.glob("#{cache_path.path}.*.part")).to be_empty

        result = cache_path.write_if_missing { |file| file.write('complete') }

        expect(result).to be(true)
        expect(File.binread(cache_path.path)).to eq('complete')
      end

      it 'reuses an existing complete artifact without invoking the writer' do
        cache_path.write_if_missing { |file| file.write('cached') }

        result = cache_path.write_if_missing do
          raise 'existing cache should be reused'
        end

        expect(result).to be(false)
        expect(File.binread(cache_path.path)).to eq('cached')
      end
    end
  end

  describe '#send_to' do
    it 'delivers only the complete bounded artifact through the response' do
      response = double('response')
      cache_path.write_if_missing { |file| file.write('complete') }

      expect(response).to receive(:send_file).with(cache_path.path)

      cache_path.send_to(response)
    end

    it 'rejects delivery before publication' do
      response = double('response')

      expect { cache_path.send_to(response) }.
        to raise_error(IOError, 'ZIP cache artifact is unavailable')
    end
  end

  describe 'validation' do
    it 'rejects an unpersisted request' do
      request = InfoRequest.allocate
      allow(request).to receive(:persisted?).and_return(false)

      expect {
        described_class.new(info_request: request, user: user)
      }.to raise_error(
        ArgumentError,
        'info_request must be a persisted InfoRequest'
      )
    end

    it 'rejects an unbounded cache version' do
      allow(info_request).to receive(:last_update_hash).and_return('../escape')

      expect { cache_path.path }.
        to raise_error(ArgumentError, 'invalid cache version')
    end
  end
end
