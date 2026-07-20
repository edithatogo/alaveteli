require 'spec_helper'

RSpec.describe RequestZipCacheVersion do
  def entry(type, identity, values)
    [type, identity, values]
  end

  def digest(entries)
    source = instance_double(described_class::Source, entries: entries)
    described_class.new(nil, source: source).hexdigest
  end

  let(:fixed_time) { Time.utc(2026, 7, 20, 0, 0, 0) }
  let(:entries) do
    [
      entry('InfoRequest', 1, ['Title', 'normal', fixed_time]),
      entry('InfoRequestEvent', 2, ['response', true, fixed_time]),
      entry('IncomingMessage', 3, ['normal', fixed_time]),
      entry('OutgoingMessage', 4, [fixed_time]),
      entry('Comment', 5, [fixed_time]),
      entry('FoiAttachment', 6, ['normal', 'attachment-md5-v1', fixed_time]),
      entry('FoiAttachmentBlob', '6:7', ['blob-checksum-v1', 100]),
      entry('RawEmail', 8, ['raw-checksum-v1', fixed_time]),
      entry('RawEmailBlob', '8:9', ['raw-blob-checksum-v1', 200]),
      entry('CensorRule', 10, ['secret', 'redacted', fixed_time]),
      entry('PublicBody::Translation', 11, %w[en Authority])
    ]
  end

  it 'changes for same-second content, visibility, and redaction mutations' do
    entries.each_index do |index|
      changed = Marshal.load(Marshal.dump(entries))
      changed[index][2][0] = "changed-#{index}"

      expect(digest(changed)).not_to eq(digest(entries)), entries[index][0]
    end
  end

  it 'distinguishes subsecond revisions within the same second' do
    revised = Marshal.load(Marshal.dump(entries))
    revised[3][2][0] = fixed_time + Rational(1, 1_000_000)

    expect(digest(revised)).not_to eq(digest(entries))
  end

  it 'changes when a relevant record is added or deleted' do
    expect(digest(entries.drop(1))).not_to eq(digest(entries))
    expect(digest(entries + [entry('Comment', 99, ['new'])])).
      not_to eq(digest(entries))
  end

  it 'sorts every collection by record type and stable identity' do
    shuffled = entries.shuffle(random: Random.new(12_345))

    expect(digest(shuffled)).to eq(digest(entries))
  end

  it 'distinguishes numeric primary keys without lexical ordering artifacts' do
    numeric = [entry('Comment', 10, ['ten']), entry('Comment', 2, ['two'])]

    expect(digest(numeric.reverse)).to eq(digest(numeric))
  end

  describe RequestZipCacheVersion::Source do
    it 'does not project derived megabyte-scale cached text columns' do
      projected_fields = described_class.constants(false).
        grep(/_FIELDS\z/).
        flat_map { |name| described_class.const_get(name) }

      expect(projected_fields).not_to include(
        :cached_attachment_text_clipped,
        :cached_main_body_text_folded,
        :cached_main_body_text_unfolded
      )
    end

    it 'uses revisions for text and persisted checksums for stored content' do
      expect(described_class::OUTGOING_FIELDS).to include(:updated_at)
      expect(described_class::OUTGOING_FIELDS).not_to include(:body)
      expect(described_class::COMMENT_FIELDS).to include(:updated_at)
      expect(described_class::COMMENT_FIELDS).not_to include(:body)
      expect(described_class::ATTACHMENT_FIELDS).to include(:hexdigest)
      expect(described_class::RAW_EMAIL_FIELDS).to include(:message_checksum)
      expect(described_class::CENSOR_RULE_FIELDS).
        to include(:text, :replacement, :updated_at)
    end

    it 'keeps repeated snapshot queries bounded and does not read bodies' do
      request = FactoryBot.create(:info_request_with_pdf_attachment)
      sql = []
      callback = ->(_name, _start, _finish, _id, payload) do
        sql << payload[:sql] unless payload[:name] == 'SCHEMA'
      end
      expect_any_instance_of(ActiveStorage::Blob).not_to receive(:download)

      subscription = ActiveSupport::Notifications.subscribe(
        'sql.active_record', &callback
      )
      2.times { RequestZipCacheVersion.new(request).hexdigest }
      ActiveSupport::Notifications.unsubscribe(subscription)

      expect(sql.length).to be <= 28
      expect(sql.join(' ')).not_to match(/cached_(attachment|main_body)_text/)
      expect(sql.join(' ')).not_to match(/MD5\(.+\.(body|text)/i)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription) if subscription
    end
  end
end
