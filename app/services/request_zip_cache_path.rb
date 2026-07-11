# frozen_string_literal: true

class RequestZipCachePath
  def self.call(cache_key:, last_update_hash:, cache_file_suffix:)
    File.join(
      InfoRequest.download_zip_dir,
      'download',
      cache_key,
      last_update_hash,
      "request#{cache_file_suffix}.zip"
    )
  end
end
