RSpec.configure do |config|
  config.after do
    BotTrafficMetrics::EVENTS.each do |event|
      Rails.cache.delete(BotTrafficMetrics.cache_key(event))
    end
  end
end
