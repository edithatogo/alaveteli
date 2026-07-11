require 'spec_helper'

RSpec.describe RequestZipDelivery do
  let(:info_request) { double('info_request') }
  let(:user) { double('user') }
  let(:cache_path) { Rails.root.join('cache', 'zips', 'test', 'request.zip') }

  before do
    allow(info_request).to receive(:make_zip_cache_path).
      with(user, cache_key: 'bounded-key').and_return(cache_path)
    allow(FileUtils).to receive(:mkdir_p).and_call_original
    allow(FileUtils).to receive(:mkdir_p).with(cache_path.dirname.to_s)
    lock_file = instance_double(File, flock: true)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).
      with("#{cache_path}.lock", File::CREAT).and_yield(lock_file)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(cache_path).and_return(false, true)
    allow(File).to receive(:chmod).and_call_original
    allow(File).to receive(:chmod).with(0644, cache_path)
  end

  it 'builds the cache once under the model-provided cache boundary' do
    generated_path = nil

    delivery = described_class.call(
      info_request: info_request,
      user: user,
      cache_key: 'bounded-key'
    ) { |path| generated_path = path }

    expect(generated_path).to eq(cache_path)
    expect(delivery).to have_attributes(
      path: cache_path.to_s,
      filename: 'request.zip'
    )
    expect(FileUtils).to have_received(:mkdir_p).
      with(cache_path.dirname.to_s)
    expect(File).to have_received(:chmod).with(0644, cache_path)
  end

  it 'does not rebuild an existing cache' do
    allow(File).to receive(:exist?).and_return(true)

    expect {
      described_class.call(
        info_request: info_request,
        user: user,
        cache_key: 'bounded-key'
      ) { raise 'cache should not be rebuilt' }
    }.not_to raise_error
  end
end
