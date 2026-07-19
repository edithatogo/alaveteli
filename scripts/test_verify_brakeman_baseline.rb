#!/usr/bin/env ruby

require 'json'
require 'minitest/autorun'
require 'tempfile'

require_relative 'verify_brakeman_baseline'

# Exercises fail-closed matching of the reviewed Brakeman warning ledger.
class BrakemanBaselineVerifierTest < Minitest::Test
  def warning
    {
      'fingerprint' => 'abc123',
      'warning_type' => 'SQL Injection',
      'warning_code' => 0,
      'check_name' => 'SQL',
      'message' => 'Possible SQL injection',
      'file' => 'app/models/example.rb',
      'line' => 12,
      'confidence' => 'Medium'
    }
  end

  def test_accepts_an_exact_approved_ledger
    output, = capture_io { verify(approved: [warning], ignored: [warning]) }

    assert_match(/Verified 1 approved Brakeman fingerprint/, output)
  end

  def test_rejects_stale_and_unapproved_fingerprints
    replacement = warning.merge('fingerprint' => 'def456')

    error = assert_raises(RuntimeError) do
      verify(approved: [warning], ignored: [replacement])
    end
    assert_match(/stale approved fingerprints/, error.message)
    assert_match(/unapproved ignored fingerprints/, error.message)
  end

  def test_rejects_changed_warning_metadata
    changed = warning.merge('line' => 13)

    error = assert_raises(RuntimeError) do
      verify(approved: [warning], ignored: [changed])
    end
    assert_match(/line=12 \(report: 13\)/, error.message)
  end

  def test_rejects_scanner_version_drift
    error = assert_raises(RuntimeError) do
      verify(approved: [warning], ignored: [warning], report_version: '8.1.0')
    end
    assert_match(/Brakeman version mismatch/, error.message)
  end

  def test_rejects_obsolete_ignores_and_scanner_errors
    error = assert_raises(RuntimeError) do
      verify(
        approved: [warning],
        ignored: [warning],
        obsolete: ['abc123'],
        errors: ['parse']
      )
    end
    assert_match(/scanner errors/, error.message)
    assert_match(/obsolete ignores/, error.message)
  end

  private

  def with_json(value)
    Tempfile.create do |file|
      file.write(JSON.generate(value))
      file.flush
      yield file.path
    end
  end

  def verify(approved:, ignored:, version: '8.0.5', report_version: version,
             obsolete: [], errors: [])
    ledger = { 'brakeman_version' => version, 'ignored_warnings' => approved }
    report = {
      'scan_info' => { 'brakeman_version' => report_version },
      'ignored_warnings' => ignored,
      'obsolete' => obsolete,
      'errors' => errors
    }
    with_json(ledger) do |ledger_path|
      with_json(report) do |report_path|
        BrakemanBaselineVerifier.verify(ledger_path, report_path)
      end
    end
  end
end
