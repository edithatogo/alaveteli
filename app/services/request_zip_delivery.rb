# frozen_string_literal: true

class RequestZipDelivery
  Delivery = Struct.new(:path, :filename, keyword_init: true)

  def self.call(info_request:, user:, cache_key:, &block)
    new(info_request: info_request, user: user, cache_key: cache_key).call(&block)
  end

  def initialize(info_request:, user:, cache_key:)
    @info_request = info_request
    @user = user
    @cache_key = cache_key
  end

  def call
    cache_path = info_request.make_zip_cache_path(user, cache_key: cache_key)
    FileUtils.mkdir_p(File.dirname(cache_path.to_s))

    File.open(lock_path(cache_path), File::CREAT) do |lock_file|
      lock_file.flock(File::LOCK_EX)
      write_cache(cache_path) unless File.exist?(cache_path)
      File.chmod(0644, cache_path) if File.exist?(cache_path)
    end

    Delivery.new(path: cache_path.to_s, filename: 'request.zip')
  end

  private

  attr_reader :info_request, :user, :cache_key

  def lock_path(cache_path)
    "#{cache_path}.lock"
  end

  def write_cache(cache_path)
    partial_path = "#{cache_path}.part"
    FileUtils.rm_f(partial_path)
    yield partial_path
    File.chmod(0644, partial_path)
    File.rename(partial_path, cache_path)
  ensure
    FileUtils.rm_f(partial_path)
  end
end
