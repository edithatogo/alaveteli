require 'spec_helper'

RSpec.describe BulkExportStreamer do
  let!(:export_started_at) { 1.second.ago }
  let!(:old_request) do
    FactoryBot.create(
      :info_request,
      title: 'Older request',
      created_at: 3.days.ago
    )
  end
  let!(:new_request) do
    FactoryBot.create(
      :info_request,
      title: 'Newer request',
      created_at: 1.day.ago
    )
  end

  def exported_rows(**options)
    described_class.new(since: export_started_at, **options).each.to_a
  end

  it 'streams selected rows in deterministic id order' do
    rows = exported_rows(batch_size: 1)

    expect(rows.map { |row| row[:id] }).to eq([old_request.id, new_request.id])
    expect(rows.first).to include(
      title: old_request.title,
      public_body_name: old_request.public_body.name,
      public_body_url_name: old_request.public_body.url_name
    )
  end

  it 'does not exclude older eligible rows when no timestamp is supplied' do
    old_request.update_columns(updated_at: 1.year.ago)

    ids = described_class.new.each.map { |row| row[:id] }

    expect(ids).to include(old_request.id, new_request.id)
  end

  it 'builds the optimized path with a public body join' do
    allow(InfoRequest).to receive(:custom_states_loaded?).and_return(false)
    allow(InfoRequest).to receive(:joins).and_call_original

    exported_rows(limit: 1)

    expect(InfoRequest).to have_received(:joins).with(:public_body)
  end

  it 'uses the Globalize fallback translation without omitting requests' do
    allow(AlaveteliLocalization).to receive(:locale).and_return('fr')
    allow(Globalize).to receive(:fallbacks).with('fr').and_return(%i[fr en])
    old_request.public_body.translations.update_all(locale: 'en')

    rows = exported_rows(batch_size: 1)
    row = rows.find { |candidate| candidate[:id] == old_request.id }
    fallback = old_request.public_body.translations.find_by!(locale: 'en')

    expect(row).to include(
      public_body_name: fallback.name,
      public_body_url_name: fallback.url_name
    )
  end

  it 'prefers the current translation and paginates each request once' do
    allow(AlaveteliLocalization).to receive(:locale).and_return('fr')
    allow(Globalize).to receive(:fallbacks).with('fr').and_return(%i[fr en])
    old_request.public_body.translations.update_all(locale: 'en')
    old_request.public_body.translations.create!(
      locale: 'fr',
      name: 'Autorite francaise',
      url_name: 'autorite-francaise'
    )

    rows = exported_rows(batch_size: 1)

    expect(rows.map { |row| row[:id] }).to eq(
      [old_request.id, new_request.id]
    )
    expect(rows.first).to include(
      public_body_name: 'Autorite francaise',
      public_body_url_name: 'autorite-francaise'
    )
  end

  it 'enforces the limit without reading past the requested row count' do
    rows = exported_rows(limit: 1, batch_size: 1)

    expect(rows.size).to eq(1)
    expect(rows.first[:id]).to eq(old_request.id)
  end

  it 'filters rows by updated timestamp' do
    cutoff = 2.days.ago
    old_request.update_columns(updated_at: cutoff - 1.second)
    new_request.update_columns(updated_at: cutoff)

    rows = described_class.new(since: cutoff, batch_size: 1).each.to_a

    expect(rows.map { |row| row[:id] }).to eq([new_request.id])
  end

  it 'preserves base calculated status for ordinary requests' do
    row = exported_rows(limit: 1).first

    expect(row[:status]).to eq(old_request.reload.calculate_status)
  end

  it 'falls back to ActiveRecord status calculation for custom states' do
    allow(InfoRequest).to receive(:custom_states_loaded?).and_return(true)

    row = exported_rows(limit: 1).first

    expect(row[:status]).to eq(old_request.reload.calculate_status)
  end
end
