require 'spec_helper'

RSpec.describe BulkExportSnapshot do
  def streamer(*rows, error: nil)
    Enumerator.new do |yielder|
      rows.each { |row| yielder << row }
      raise error if error
    end
  end

  it 'hashes the exact immutable NDJSON body bytes' do
    snapshot = described_class.new(
      streamer: streamer({ id: 1, title: 'First' }, { id: 2, title: 'Second' })
    )
    body = snapshot.each.to_a.join

    expect(snapshot.etag).to eq(Digest::SHA256.hexdigest(body))
    expect(body).to eq(
      "{\"id\":1,\"title\":\"First\"}\n" \
      "{\"id\":2,\"title\":\"Second\"}\n"
    )
  end

  it 'serializes the export source exactly once' do
    source = instance_double(BulkExportStreamer)
    expect(source).to receive(:each).once.and_yield({ id: 1 })

    snapshot = described_class.new(streamer: source)
    snapshot.each.to_a
  end

  it 'creates a permission-restricted file and unlinks it after iteration' do
    snapshot = described_class.new(streamer: streamer({ id: 1 }))
    path = snapshot.path

    expect(File.stat(path).mode & 0o777).to eq(0o600)

    snapshot.each.to_a

    expect(File.exist?(path)).to be(false)
  end

  it 'unlinks the file when Rack closes the body without iteration' do
    snapshot = described_class.new(streamer: streamer({ id: 1 }))
    path = snapshot.path

    snapshot.close

    expect(File.exist?(path)).to be(false)
  end

  it 'unlinks the file when a stream consumer fails' do
    snapshot = described_class.new(streamer: streamer({ id: 1 }))
    path = snapshot.path

    expect do
      snapshot.each { raise 'consumer failed' }
    end.to raise_error('consumer failed')

    expect(File.exist?(path)).to be(false)
  end

  it 'unlinks a partial file when snapshot construction fails' do
    paths = []
    allow(Tempfile).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap { |file| paths << file.path }
    end

    expect do
      described_class.new(
        streamer: streamer({ id: 1 }, error: RuntimeError.new('export failed'))
      )
    end.to raise_error('export failed')

    expect(paths).not_to be_empty
    expect(paths).to all(satisfy { |path| !File.exist?(path) })
  end

  it 'changes the ETag when the exact date-sensitive status bytes change' do
    waiting = described_class.new(
      streamer: streamer({ id: 1, status: 'waiting_response' })
    )
    overdue = described_class.new(
      streamer: streamer({ id: 1, status: 'waiting_response_overdue' })
    )

    expect(waiting.etag).not_to eq(overdue.etag)
  ensure
    waiting&.close!
    overdue&.close!
  end
end
