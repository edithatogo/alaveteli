#!/usr/bin/env ruby

require 'json'

# Verifies that Brakeman output exactly matches the reviewed warning ledger.
module BrakemanBaselineVerifier
  METADATA_FIELDS = %w[
    warning_type warning_code check_name message file line confidence
  ].freeze

  module_function

  def verify(ignore_path, report_path)
    ledger = JSON.parse(File.read(ignore_path))
    report = JSON.parse(File.read(report_path))

    expected_version = ledger.fetch('brakeman_version')
    actual_version = report.dig('scan_info', 'brakeman_version')
    unless actual_version == expected_version
      raise "Brakeman version mismatch: expected #{expected_version}, " \
            "got #{actual_version.inspect}"
    end

    approved = index_by_fingerprint(
      ledger.fetch('ignored_warnings'), 'approved ledger'
    )
    ignored = index_by_fingerprint(
      report.fetch('ignored_warnings'), 'Brakeman report'
    )

    missing = approved.keys - ignored.keys
    unapproved = ignored.keys - approved.keys
    errors = []
    unless missing.empty?
      errors << "stale approved fingerprints: #{missing.sort.join(', ')}"
    end
    unless unapproved.empty?
      errors << "unapproved ignored fingerprints: #{unapproved.sort.join(', ')}"
    end

    (approved.keys & ignored.keys).sort.each do |fingerprint|
      mismatches = METADATA_FIELDS.each_with_object([]) do |field, result|
        next if approved[fingerprint][field] == ignored[fingerprint][field]

        result << "#{field}=#{approved[fingerprint][field].inspect} " \
                  "(report: #{ignored[fingerprint][field].inspect})"
      end
      unless mismatches.empty?
        errors << "#{fingerprint}: #{mismatches.join('; ')}"
      end
    end

    report_errors = report.fetch('errors', [])
    unless report_errors.empty?
      errors << "scanner errors: #{report_errors.inspect}"
    end
    obsolete = report.fetch('obsolete', [])
    unless obsolete.empty?
      errors << "Brakeman reported obsolete ignores: #{obsolete.inspect}"
    end

    raise errors.join("\n") unless errors.empty?

    puts "Verified #{approved.length} approved Brakeman fingerprints " \
         "with #{expected_version}."
  end

  def index_by_fingerprint(entries, source)
    entries.each_with_object({}) do |entry, index|
      fingerprint = entry.fetch('fingerprint')
      if index.key?(fingerprint)
        raise "Duplicate fingerprint in #{source}: #{fingerprint}"
      end

      missing = METADATA_FIELDS.reject { |field| entry.key?(field) }
      unless missing.empty?
        raise "#{fingerprint} lacks metadata in #{source}: #{missing.join(', ')}"
      end

      index[fingerprint] = entry
    end
  end
end

if $PROGRAM_NAME == __FILE__
  unless ARGV.length == 2
    abort "Usage: #{$PROGRAM_NAME} IGNORE_FILE BRAKEMAN_REPORT"
  end

  BrakemanBaselineVerifier.verify(*ARGV)
end
