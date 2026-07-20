# frozen_string_literal: true

require 'digest'

# Builds a deterministic digest from narrow, authoritative request ZIP inputs.
class RequestZipCacheVersion
  SCHEMA_VERSION = 2

  # Projects output-relevant revision values without loading cached text or
  # attachment bodies. Collection queries are ordered and bounded by type.
  class Source
    REQUEST_FIELDS = %i[
      title url_title user_id public_body_id prominence prominence_reason
      external_user_name external_url created_at updated_at
    ].freeze
    PUBLIC_BODY_FIELDS = %i[
      version name short_name request_email url_name updated_at
    ].freeze
    USER_FIELDS = %i[id name url_name updated_at].freeze
    TRANSLATION_FIELDS = %i[
      id locale name short_name request_email url_name first_letter
      publication_scheme disclosure_log
    ].freeze
    EVENT_FIELDS = %i[
      id event_type created_at updated_at described_state calculated_state
      last_described_at incoming_message_id outgoing_message_id comment_id
      params
    ].freeze
    OUTGOING_FIELDS = %i[
      id status message_type created_at updated_at last_sent_at
      incoming_message_followup_id what_doing prominence prominence_reason
      from_name
    ].freeze
    INCOMING_FIELDS = %i[
      id raw_email_id created_at updated_at subject from_email_domain
      valid_to_reply_to from_name sent_at prominence prominence_reason
      from_email last_parsed
    ].freeze
    COMMENT_FIELDS = %i[
      id user_id visible created_at updated_at locale attention_requested
    ].freeze
    ATTACHMENT_FIELDS = %i[
      id incoming_message_id content_type filename charset display_size
      url_part_number within_rfc822_subject hexdigest created_at updated_at
      prominence prominence_reason masked_at locked replaced_at replaced_reason
      erased_at
    ].freeze
    RAW_EMAIL_FIELDS = %i[
      id created_at updated_at erased_at message_id message_checksum
    ].freeze
    CENSOR_RULE_FIELDS = %i[
      id text replacement updated_at regexp case_sensitive ignore_diacritics
      censorable_type censorable_id
    ].freeze

    attr_reader :info_request

    def initialize(info_request)
      @info_request = info_request
    end

    def entries
      @entries ||= [
        configuration_entries,
        request_entries,
        public_body_entries,
        translation_entries,
        user_entries,
        relation_entries('InfoRequestEvent', info_request.info_request_events,
                         EVENT_FIELDS),
        outgoing_entries,
        incoming_entries,
        comment_entries,
        attachment_entries,
        blob_entries('FoiAttachment', attachment_ids),
        raw_email_entries,
        blob_entries('RawEmail', raw_email_ids),
        censor_rule_entries
      ].flatten(1)
    end

    private

    def configuration_entries
      [
        entry('Configuration', 'domain', AlaveteliConfiguration.domain.to_s),
        entry('Configuration', 'locale', I18n.locale.to_s),
        entry('Configuration', 'masks', info_request.masks)
      ]
    end

    def request_entries
      [object_entry('InfoRequest', info_request, REQUEST_FIELDS)]
    end

    def public_body_entries
      return [] unless info_request.public_body

      [object_entry('PublicBody', info_request.public_body, PUBLIC_BODY_FIELDS)]
    end

    def translation_entries
      return [] unless info_request.public_body

      relation_entries('PublicBody::Translation',
                       info_request.public_body.translations,
                       TRANSLATION_FIELDS)
    end

    def user_entries
      return [] unless info_request.user

      [object_entry('User', info_request.user, USER_FIELDS)]
    end

    def outgoing_entries
      relation_entries(
        'OutgoingMessage', info_request.outgoing_messages, OUTGOING_FIELDS
      )
    end

    def comment_entries
      relation = info_request.comments.left_outer_joins(:user)
      fields = COMMENT_FIELDS + ['users.id', 'users.name', 'users.updated_at']
      projected_relation_entries('Comment', relation, fields)
    end

    def attachment_entries
      @attachment_entries ||= relation_entries(
        'FoiAttachment', info_request.foi_attachments, ATTACHMENT_FIELDS
      )
    end

    def incoming_entries
      @incoming_entries ||= relation_entries(
        'IncomingMessage', info_request.incoming_messages, INCOMING_FIELDS
      )
    end

    def attachment_ids
      attachment_entries.map { |item| item.fetch(1) }
    end

    def raw_email_entries
      @raw_email_entries ||= relation_entries(
        'RawEmail', RawEmail.where(id: raw_email_ids), RAW_EMAIL_FIELDS
      )
    end

    def raw_email_ids
      @raw_email_ids ||= incoming_entries.map { |item| item[2][0] }.compact
    end

    def blob_entries(record_type, record_ids)
      return [] if record_ids.empty?

      rows = ActiveStorage::Attachment.joins(:blob).
        where(record_type: record_type, record_id: record_ids, name: 'file').
        reorder('active_storage_attachments.record_id',
                'active_storage_attachments.id').
        pluck(:record_id, :id, 'active_storage_blobs.id',
              'active_storage_blobs.key', 'active_storage_blobs.checksum',
              'active_storage_blobs.byte_size',
              'active_storage_blobs.created_at')
      rows.map do |row|
        entry("#{record_type}Blob", "#{row[0]}:#{row[1]}", row.drop(2))
      end
    end

    def censor_rule_entries
      scope = CensorRule.where(censorable_type: nil, censorable_id: nil)
      scope = scope.or(CensorRule.where(censorable: info_request))
      if info_request.public_body
        scope = scope.or(
          CensorRule.where(censorable: info_request.public_body)
        )
      end
      scope = scope.or(CensorRule.where(censorable: info_request.user)) if
        info_request.user
      relation_entries('CensorRule', scope, CENSOR_RULE_FIELDS)
    end

    def relation_entries(type, relation, fields)
      projected_relation_entries(type, relation, fields)
    end

    def projected_relation_entries(type, relation, fields)
      order = relation.klass.arel_table[:id]
      relation.reorder(order).pluck(*fields).map do |row|
        values = Array(row)
        entry(type, values.first, values.drop(1))
      end
    end

    def object_entry(type, object, fields)
      values = fields.map { |field| object.public_send(field) }
      entry(type, object.id, values)
    end

    def entry(type, identity, values)
      [type, identity, values]
    end
  end

  attr_reader :source

  def initialize(info_request, source: Source.new(info_request))
    @source = source
  end

  def hexdigest
    digest = Digest::SHA256.new
    append(digest, 'schema', SCHEMA_VERSION)
    sorted_entries.each do |type, identity, values|
      append(digest, type, [identity, values])
    end
    digest.hexdigest
  end

  private

  def sorted_entries
    source.entries.sort_by do |type, identity, _values|
      [type.to_s, stable_identity(identity)]
    end
  end

  def stable_identity(identity)
    return [0, identity] if identity.is_a?(Integer)

    [1, identity.to_s]
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
