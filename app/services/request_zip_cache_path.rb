# frozen_string_literal: true

require 'securerandom'

# Coordinates private, bounded request ZIP cache artifacts.
class RequestZipCachePath
  DOWNLOAD_FILENAME = 'request-correspondence.zip'
  CACHE_FILENAME = 'correspondence.zip'
  LOCK_SUFFIX = '.lock'
  TEMP_SUFFIX = '.part'
  VERSION_PATTERN = /\A[0-9a-f]{64}\z/

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
    prepare_directory!
    validate_directory_chain!

    with_lock do
      validate_directory_chain!
      return false if published?

      cleanup_stale_temps!
      publish { |file| yield file }
    end
  end

  def send_to(response)
    validate_directory_chain!
    raise IOError, 'ZIP cache artifact is unavailable' unless published?

    response.send_file(path)
  end

  private

  def validate!
    unless info_request.is_a?(InfoRequest) && info_request.persisted?
      raise ArgumentError, 'info_request must be a persisted InfoRequest'
    end

    raise ArgumentError, 'invalid request id' unless info_request.id.positive?
    return if VERSION_PATTERN.match?(version)

    raise ArgumentError, 'invalid cache version'
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
    @version ||= info_request.zip_cache_version.to_s
  end

  def cache_filename
    basename = File.basename(CACHE_FILENAME, '.zip')
    "#{basename}#{info_request.zip_cache_file_suffix(user)}.zip"
  end

  def prepare_directory!
    prepare_root!
    current = root
    directory_components.each do |component|
      current = File.join(current, component)
      begin
        Dir.mkdir(current, 0o700)
      rescue Errno::EEXIST
        # Validated below without following the existing component.
      end
      validate_directory!(current)
      File.chmod(0o700, current)
    end
  end

  def prepare_root!
    begin
      File.lstat(root)
    rescue Errno::ENOENT
      FileUtils.mkdir_p(root, mode: 0o700)
    end
    validate_directory!(root)
  end

  def directory_components
    ['download', shard, request_id, version]
  end

  def validate_directory_chain!
    validate_directory!(root)
    current = root
    directory_components.each do |component|
      current = File.join(current, component)
      validate_directory!(current)
    end
  end

  def validate_directory!(candidate)
    stat = File.lstat(candidate)
    return if stat.directory? && !stat.symlink?

    raise SecurityError, "unsafe ZIP cache directory: #{candidate}"
  rescue Errno::ENOENT
    raise SecurityError, "missing ZIP cache directory: #{candidate}"
  end

  def with_lock
    validate_directory_chain!
    File.open(lock_path, lock_open_flags, 0o600) do |lock|
      lock.chmod(0o600)
      unless lock.flock(File::LOCK_EX)
        raise IOError, 'could not lock ZIP cache path'
      end

      validate_directory_chain!
      yield
    end
  end

  def lock_path
    "#{path}#{LOCK_SUFFIX}"
  end

  def lock_open_flags
    flags = File::RDWR | File::CREAT
    flags |= File::NOFOLLOW if defined?(File::NOFOLLOW)
    flags
  end

  def published?
    validate_directory_chain!
    return false unless File.exist?(path)

    unless File.lstat(path).file?
      raise SecurityError, 'ZIP cache artifact is not a regular file'
    end

    File.chmod(0o600, path)
    true
  end

  def publish
    validate_directory_chain!
    temporary_path = new_temporary_path
    File.open(temporary_path, temporary_open_flags, 0o600) do |file|
      yield file
      file.flush
      file.fsync
    end
    validate_directory_chain!
    File.rename(temporary_path, path)
    File.chmod(0o600, path)
    fsync_directory!
    true
  ensure
    FileUtils.rm_f(temporary_path) if temporary_path
  end

  def new_temporary_path
    "#{path}.#{Process.pid}-#{SecureRandom.hex(12)}#{TEMP_SUFFIX}"
  end

  def temporary_open_flags
    flags = File::WRONLY | File::CREAT | File::EXCL
    flags |= File::NOFOLLOW if defined?(File::NOFOLLOW)
    flags
  end

  def cleanup_stale_temps!
    validate_directory_chain!
    prefix = "#{File.basename(path)}."
    Dir.children(directory).each do |entry|
      next unless entry.start_with?(prefix) && entry.end_with?(TEMP_SUFFIX)

      candidate = File.join(directory, entry)
      FileUtils.rm_f(candidate) if File.lstat(candidate).file?
    rescue Errno::ENOENT
      next
    end
  end

  def fsync_directory!
    File.open(directory, File::RDONLY, &:fsync)
  end
end
