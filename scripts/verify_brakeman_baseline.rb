#!/usr/bin/env ruby

require 'json'

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
      raise "Brakeman version mismatch: expected #{expected_version}, got #{actual_version.inspect}"
    end

    approved = index_by_fingerprint(ledger.fetch('ignored_warnings'), 'approved ledger')
    ignored = index_by_fingerprint(report.fetch('ignored_warnings'), 'Brakeman report')

    missing = approved.keys - ignored.keys
    unapproved = ignored.keys - approved.keys
    errors = []
    errors << "stale approved fingerprints: #{missing.sort.join(', ')}" unless missing.empty?
    errors << "unapproved ignored fingerprints: #{unapproved.sort.join(', ')}" unless unapproved.empty?

    (approved.keys & ignored.keys).sort.each do |fingerprint|
      mismatches = METADATA_FIELDS.filter_map do |field|
        next if approved[fingerprint][field] == ignored[fingerprint][field]

        "#{field}=#{approved[fingerprint][field].inspect} " \
          "(report: #{ignored[fingerprint][field].inspect})"
      end
      errors << "#{fingerprint}: #{mismatches.join('; ')}" unless mismatches.empty?
    end

    report_errors = report.fetch('errors', [])
    errors << "scanner errors: #{report_errors.inspect}" unless report_errors.empty?
    obsolete = report.fetch('obsolete', [])
    errors << "Brakeman reported obsolete ignores: #{obsolete.inspect}" unless obsolete.empty?

    raise errors.join("\n") unless errors.empty?

    puts "Verified #{approved.length} approved Brakeman fingerprints with #{expected_version}."
  end

  def index_by_fingerprint(entries, source)
    entries.each_with_object({}) do |entry, index|
      fingerprint = entry.fetch('fingerprint')
      raise "Duplicate fingerprint in #{source}: #{fingerprint}" if index.key?(fingerprint)

      missing = METADATA_FIELDS.reject { |field| entry.key?(field) }
      unless missing.empty?
        raise "#{fingerprint} lacks metadata in #{source}: #{missing.join(', ')}"
      end

      index[fingerprint] = entry
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Usage: #{$PROGRAM_NAME} IGNORE_FILE BRAKEMAN_REPORT" unless ARGV.length == 2

  BrakemanBaselineVerifier.verify(*ARGV)
end
