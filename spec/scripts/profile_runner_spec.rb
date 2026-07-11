require 'spec_helper'
require 'open3'
require 'tmpdir'

RSpec.describe 'scripts/profile_runner.rb' do
  it 'serializes a profiler result without a to_h method as an empty object' do
    stub_dir = Dir.mktmpdir('profile-runner-vernier')
    profile_path = Rails.root.join('tmp/profiles/rate_limit_profile.json')
    FileUtils.rm_f(profile_path)
    File.write(File.join(stub_dir, 'vernier.rb'), <<~RUBY)
      module Vernier
        def self.trace(profile:)
          yield
          Object.new
        end
      end
    RUBY

    stdout, stderr, status = Open3.capture3(
      { 'RUBYLIB' => stub_dir },
      RbConfig.ruby,
      Rails.root.join('scripts/profile_runner.rb').to_s,
      'rate_limit',
      chdir: Rails.root.to_s
    )

    expect(status).to be_success, "stdout: #{stdout}\nstderr: #{stderr}"
    expect(JSON.parse(File.read(profile_path))).to eq({})
  ensure
    FileUtils.rm_f(profile_path)
    FileUtils.remove_entry(stub_dir) if stub_dir && File.directory?(stub_dir)
  end
end
