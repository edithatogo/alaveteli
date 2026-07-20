# frozen_string_literal: true

require 'digest'
require 'tempfile'

class BulkExportSnapshot
  attr_reader :etag, :path

  def initialize(limit: nil, since: nil, streamer: nil)
    @tempfile = Tempfile.new(['bulk-export-', '.ndjson'])
    @tempfile.binmode
    @tempfile.chmod(0o600)
    @path = @tempfile.path
    @streamer = streamer || BulkExportStreamer.new(limit: limit, since: since)
    build!
  rescue StandardError
    close!
    raise
  end

  def each
    return enum_for(__method__) unless block_given?

    begin
      tempfile.rewind
      tempfile.each_line { |line| yield line }
    ensure
      close!
    end
  end

  def close
    close!
  end

  def close!
    tempfile&.close!
    @tempfile = nil
  end

  private

  attr_reader :streamer, :tempfile

  def build!
    digest = Digest::SHA256.new

    streamer.each do |row|
      line = "#{row.to_json}\n"
      tempfile.write(line)
      digest << line
    end

    tempfile.flush
    tempfile.fsync
    @etag = digest.hexdigest
  end
end
