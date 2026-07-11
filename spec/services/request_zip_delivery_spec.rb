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
    allow(FileUtils).to receive(:rm_f).and_call_original
    allow(FileUtils).to receive(:rm_f).with("#{cache_path}.part")
    lock_file = instance_double(File)
    allow(lock_file).to receive(:flock).and_return(true)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).
      with("#{cache_path}.lock", File::CREAT).and_yield(lock_file)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(cache_path).and_return(false, true)
    allow(File).to receive(:chmod).and_call_original
    allow(File).to receive(:chmod).with(0644, anything)
    allow(File).to receive(:rename).and_call_original
    allow(File).to receive(:rename).
      with("#{cache_path}.part", cache_path)
  end

  it 'builds the cache once under the model-provided cache boundary' do
    generated_path = nil

    delivery = described_class.call(
      info_request: info_request,
      user: user,
      cache_key: 'bounded-key'
    ) { |path| generated_path = path }

    expect(generated_path).to eq("#{cache_path}.part")
    expect(delivery).to have_attributes(
      path: cache_path.to_s,
      filename: 'request.zip'
    )
    expect(FileUtils).to have_received(:mkdir_p).
      with(cache_path.dirname.to_s)
    expect(File).to have_received(:rename).
      with("#{cache_path}.part", cache_path)
    expect(FileUtils).to have_received(:rm_f).
      with("#{cache_path}.part").twice
    expect(lock_file).to have_received(:flock).with(File::LOCK_EX)
  end

  it 'removes the partial artifact when ZIP generation fails' do
    expect {
      described_class.call(
        info_request: info_request,
        user: user,
        cache_key: 'bounded-key'
      ) { raise 'generation failed' }
    }.to raise_error('generation failed')

    expect(File).not_to have_received(:rename)
    expect(FileUtils).to have_received(:rm_f).
      with("#{cache_path}.part").twice
  end

end
