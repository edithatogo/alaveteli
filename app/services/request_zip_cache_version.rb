# frozen_string_literal: true

require 'digest'

# Builds a deterministic digest of every authoritative request ZIP input.
class RequestZipCacheVersion
  SCHEMA_VERSION = 1

  attr_reader :info_request

  def initialize(info_request)
    @info_request = info_request
  end

  def hexdigest
    digest = Digest::SHA256.new
    append(digest, 'schema', SCHEMA_VERSION)
    append(digest, 'locale', I18n.locale.to_s)
    append(digest, 'domain', AlaveteliConfiguration.domain.to_s)
    append(digest, 'masks', info_request.masks)

    append_record(digest, 'request', info_request)
    append_record(digest, 'public_body', info_request.public_body)
    append_records(digest, 'public_body_translations', public_body_translations)
    append_record(digest, 'request_user', info_request.user)
    append_records(digest, 'events', info_request.info_request_events)
    append_records(digest, 'outgoing_messages', info_request.outgoing_messages)
    append_records(digest, 'incoming_messages', info_request.incoming_messages)
    append_records(digest, 'comments', info_request.comments)
    append_records(digest, 'comment_users', comment_users)
    append_records(digest, 'attachments', info_request.foi_attachments)
    append_records(digest, 'attachment_blobs', attachment_blobs)
    append_records(digest, 'raw_emails', raw_emails)
    append_records(digest, 'raw_email_blobs', raw_email_blobs)
    append_records(digest, 'censor_rules', info_request.applicable_censor_rules)
    digest.hexdigest
  end

  private

  def append_records(digest, label, records)
    records.to_a.each_with_index do |record, index|
      append_record(digest, "#{label}[#{index}]", record)
    end
  end

  def append_record(digest, label, record)
    append(digest, label, record&.attributes)
  end

  def comment_users
    info_request.comments.filter_map(&:user)
  end

  def public_body_translations
    info_request.public_body&.translations || []
  end

  def attachment_blobs
    info_request.foi_attachments.filter_map(&:file_blob)
  end

  def raw_emails
    info_request.incoming_messages.filter_map(&:raw_email)
  end

  def raw_email_blobs
    raw_emails.filter_map(&:file_blob)
  end

  def append(digest, label, value)
    bytes = canonical(value)
    digest << "#{label.bytesize}:#{label}#{bytes.bytesize}:"
    digest << bytes
  end

  def canonical(value)
    case value
    when nil
      'nil'
    when true, false, Integer
      "#{value.class.name}:#{value}"
    when String
      "String:#{value.b.bytesize}:#{value.b}"
    when Time
      "Time:#{value.utc.iso8601(9)}"
    when DateTime
      "DateTime:#{value.new_offset(0).iso8601(9)}"
    when Date
      "Date:#{value.iso8601}"
    when BigDecimal
      "BigDecimal:#{value.to_s('F')}"
    when Array
      "Array:[#{value.map { |item| canonical(item) }.join}]"
    when Hash
      pairs = value.sort_by { |key, _| canonical(key) }
      encoded_pairs = pairs.map do |key, item|
        canonical(key) + canonical(item)
      end
      "Hash:{#{encoded_pairs.join}}"
    else
      "#{value.class.name}:#{value}"
    end
  end
end
