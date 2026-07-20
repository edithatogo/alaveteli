# frozen_string_literal: true

class RequestZipCachePath
  DOWNLOAD_FILENAME = 'request-correspondence.zip'
  CACHE_FILENAME = 'correspondence.zip'
  VERSION_PATTERN = /\A[0-9a-f]{40}\z/

  attr_reader :info_request, :user

  def initialize(info_request:, user:)
    @info_request = info_request
    @user = user

    validate!
  end

  def path
    @path ||= File.join(directory, cache_filename)
  end

  def directory
    @directory ||= File.join(root, 'download', shard, request_id, version)
  end

  def write_if_missing
    FileUtils.mkdir_p(directory, mode: 0700)
    File.chmod(0700, directory)
    File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0600) do |file|
      yield file
    end
    secure!
    true
  rescue Errno::EEXIST
    false
  rescue StandardError
    FileUtils.rm_f(path)
    raise
  end

  def secure!
    File.chmod(0600, path)
  end

  private

  def validate!
    unless info_request.is_a?(InfoRequest) && info_request.persisted?
      raise ArgumentError, 'info_request must be a persisted InfoRequest'
    end

    raise ArgumentError, 'invalid request id' unless info_request.id.positive?
    raise ArgumentError, 'invalid cache version' unless VERSION_PATTERN.match?(version)
  end

  def root
    @root ||= File.expand_path(InfoRequest.download_zip_dir)
  end

  def request_id
    @request_id ||= info_request.id.to_s
  end

  def shard
    request_id[0, 3]
  end

  def version
    @version ||= info_request.last_update_hash.to_s
  end

  def cache_filename
    basename = File.basename(CACHE_FILENAME, '.zip')
    "#{basename}#{info_request.zip_cache_file_suffix(user)}.zip"
  end
end
