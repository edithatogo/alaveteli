require 'spec_helper'
require 'ostruct'

RSpec.describe RequestZipCacheVersion do
  FIXED_TIME = Time.utc(2026, 7, 20, 0, 0, 0)

  def record(id, attributes = {}, **associations)
    OpenStruct.new(
      { attributes: {
        'id' => id,
        'updated_at' => FIXED_TIME
      }.merge(attributes) }.merge(associations)
    )
  end

  def build_request
    comment_user = record(20, 'name' => 'Commenter')
    comment = record(19, { 'body' => 'Annotation' }, user: comment_user)
    attachment_blob = record(18, 'checksum' => 'attachment-v1')
    attachment = record(
      17,
      { 'filename' => 'evidence.pdf', 'prominence' => 'normal' },
      file_blob: attachment_blob
    )
    raw_blob = record(16, 'checksum' => 'raw-v1')
    raw_email = record(
      15,
      { 'message_checksum' => 'message-v1' },
      file_blob: raw_blob
    )
    incoming = record(
      14,
      { 'prominence' => 'normal', 'subject' => 'Response' },
      raw_email: raw_email
    )

    OpenStruct.new(
      attributes: {
        'id' => 13,
        'title' => 'Request title',
        'updated_at' => FIXED_TIME
      },
      masks: [{ to_replace: 'private', replacement: '[redacted]' }],
      public_body: record(
        12,
        { 'name' => 'Authority' },
        translations: [record(21, 'locale' => 'en', 'name' => 'Authority')]
      ),
      user: record(11, 'name' => 'Requester'),
      info_request_events: [record(10, 'visible' => true)],
      outgoing_messages: [record(9, 'body' => 'Question',
                                    'prominence' => 'normal')],
      incoming_messages: [incoming],
      comments: [comment],
      foi_attachments: [attachment],
      applicable_censor_rules: [record(8, 'text' => 'secret',
                                          'replacement' => 'x')]
    )
  end

  def digest(request)
    described_class.new(request).hexdigest
  end

  it 'changes for same-second mutations to every ZIP representation input' do
    mutations = {
      request: ->(request) { request.attributes['title'] = 'Changed' },
      authority: ->(request) do
        request.public_body.attributes['name'] = 'Changed'
      end,
      authority_translation: ->(request) do
        request.public_body.translations.first.attributes['name'] = 'Changed'
      end,
      requester: ->(request) { request.user.attributes['name'] = 'Changed' },
      event_visibility: ->(request) {
        request.info_request_events.first.attributes['visible'] = false
      },
      outgoing_message: ->(request) {
        request.outgoing_messages.first.attributes['body'] = 'Changed'
      },
      incoming_visibility: ->(request) {
        request.incoming_messages.first.attributes['prominence'] = 'hidden'
      },
      comment: ->(request) do
        request.comments.first.attributes['body'] = 'Changed'
      end,
      comment_user: ->(request) {
        request.comments.first.user.attributes['name'] = 'Changed'
      },
      attachment: ->(request) {
        request.foi_attachments.first.attributes['filename'] = 'changed.pdf'
      },
      attachment_content: ->(request) {
        request.foi_attachments.first.file_blob.attributes['checksum'] =
          'changed'
      },
      raw_email: ->(request) {
        raw_email = request.incoming_messages.first.raw_email
        raw_email.attributes['message_checksum'] = 'changed'
      },
      raw_email_content: ->(request) {
        raw_email = request.incoming_messages.first.raw_email
        raw_email.file_blob.attributes['checksum'] = 'changed'
      },
      censor_rule: ->(request) {
        request.applicable_censor_rules.first.attributes['replacement'] =
          'changed'
      },
      masks: ->(request) { request.masks.first[:replacement] = '[changed]' }
    }

    mutations.each do |label, mutate|
      request = build_request
      original = digest(request)
      mutate.call(request)

      expect(digest(request)).not_to eq(original), label.to_s
    end
  end

  it 'changes when a relevant record is deleted without a timestamp advance' do
    request = build_request
    original = digest(request)

    request.foi_attachments.clear

    expect(digest(request)).not_to eq(original)
  end

  it 'is stable for identical snapshots' do
    expect(digest(build_request)).to eq(digest(build_request))
  end
end
