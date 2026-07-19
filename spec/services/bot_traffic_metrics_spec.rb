require 'spec_helper'

RSpec.describe BotTrafficMetrics do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(cache)

    described_class::EVENTS.each do |event|
      cache.delete(described_class.cache_key(event))
    end
  end

  it 'increments known event counters' do
    described_class.increment(:cache_hits)

    expect(described_class.snapshot[:cache_hits]).to eq(1)
  end

  it 'writes the initial value when the cache cannot increment' do
    allow(cache).to receive(:increment).and_return(nil)

    described_class.increment(:cache_hits)

    expect(cache).to have_received(:increment).with(
      described_class.cache_key(:cache_hits), 1, expires_in: 30.days
    )
    expect(cache.read(described_class.cache_key(:cache_hits))).to eq(1)
  end

  it 'ignores unknown event counters' do
    described_class.increment(:unknown_event)

    expect(described_class.snapshot.values).to all(eq(0))
  end

  it 'returns zero counters when snapshot collection fails' do
    allow(Rails.cache).to receive(:read).and_raise(StandardError, 'cache down')
    allow(Rails.logger).to receive(:error)

    expect(described_class.snapshot.values).to all(eq(0))
    expect(Rails.logger).to have_received(:error).
      with(/Bot traffic metric snapshot failed:/)
  end
end
