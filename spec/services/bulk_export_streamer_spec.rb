require 'spec_helper'

RSpec.describe BulkExportStreamer do
  let(:window_start) { Time.zone.local(2040, 1, 1) }

  around do |example|
    AlaveteliLocalization.with_locale(AlaveteliLocalization.default_locale) do
      example.run
    end
  end

  let!(:old_request) do
    FactoryBot.create(
      :info_request,
      title: 'Older request',
      created_at: window_start,
      updated_at: window_start
    )
  end
  let!(:new_request) do
    FactoryBot.create(
      :info_request,
      title: 'Newer request',
      created_at: window_start + 1.day,
      updated_at: window_start + 1.day
    )
  end

  it 'streams selected rows in deterministic id order' do
    rows = described_class.new(since: window_start, batch_size: 1).each.to_a

    expect(rows.map { |row| row[:id] }).to eq([old_request.id, new_request.id])
    expect(rows.first).to include(
      title: old_request.title,
      public_body_name: old_request.public_body.name,
      public_body_url_name: old_request.public_body.url_name
    )
  end

  it 'builds the optimized path with a public body join' do
    allow(InfoRequest).to receive(:custom_states_loaded?).and_return(false)
    allow(InfoRequest).to receive(:joins).and_call_original

    described_class.new(limit: 1, since: window_start).each.to_a

    expect(InfoRequest).to have_received(:joins).with(public_body: :translations)
  end

  it 'enforces the limit without reading past the requested row count' do
    rows = described_class.new(limit: 1, since: window_start, batch_size: 1).each.to_a

    expect(rows.size).to eq(1)
    expect(rows.first[:id]).to eq(old_request.id)
  end

  it 'filters rows by updated timestamp' do
    rows = described_class.new(since: window_start + 12.hours, batch_size: 1).each.to_a

    expect(rows.map { |row| row[:id] }).to eq([new_request.id])
  end

  it 'preserves base calculated status for ordinary requests' do
    row = described_class.new(limit: 1, since: window_start).each.first

    expect(row[:status]).to eq(old_request.calculate_status)
  end

  it 'falls back to ActiveRecord status calculation for custom states' do
    allow(InfoRequest).to receive(:custom_states_loaded?).and_return(true)

    row = described_class.new(limit: 1, since: window_start).each.first

    expect(row[:status]).to eq(old_request.calculate_status)
  end
end
