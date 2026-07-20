require 'spec_helper'

RSpec.describe RequestZipCachePath do
  subject(:cache_path) do
    described_class.new(info_request: info_request, user: user)
  end

  let(:info_request) { FactoryBot.create(:info_request, id: 123_456) }
  let(:user) { info_request.user }
  let(:version) { 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3' }

  before do
    allow(info_request).to receive(:last_update_hash).and_return(version)
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
      info_request.url_title = '../../../../tmp/escape'

      expect(cache_path.path).not_to include('..')
      expect(cache_path.path).not_to include('escape')
    end

    it 'does not change when the URL title changes or aliases the request' do
      original_path = cache_path.path
      info_request.url_title = 'a-renamed-request'

      expect(
        described_class.new(info_request: info_request, user: user).path
      ).to eq(original_path)
    end

    it 'uses distinct paths for distinct authoritative request ids' do
      other_request = FactoryBot.create(:info_request, id: 123_457)
      allow(other_request).to receive(:last_update_hash).and_return(version)

      other_path = described_class.new(
        info_request: other_request,
        user: other_request.user
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
      expect(cache_path.write_if_missing { |file| file.write('zip') }).to be(true)

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
  end

  describe 'validation' do
    it 'rejects an unpersisted request' do
      request = FactoryBot.build(:info_request)

      expect {
        described_class.new(info_request: request, user: user)
      }.to raise_error(ArgumentError, 'info_request must be a persisted InfoRequest')
    end

    it 'rejects an unbounded cache version' do
      allow(info_request).to receive(:last_update_hash).and_return('../escape')

      expect { cache_path.path }.
        to raise_error(ArgumentError, 'invalid cache version')
    end
  end
end
