# frozen_string_literal: true

class RackAttackRateLimitStatus
  class BackendUnavailable < StandardError
  end

  THROTTLE_PREFIX = 'req/'.freeze

  attr_reader :advisory_status, :limit, :remaining, :reset_in_seconds, :tier

  def initialize(request:, high_system_load: Rack::Attack.high_system_load?)
    name, data = throttle_for(request)
    validate!(name, data)

    @tier = name.delete_prefix(THROTTLE_PREFIX)
    @limit = Integer(data.fetch(:limit))
    count = Integer(data.fetch(:count))
    period = Integer(data.fetch(:period))
    epoch_time = Integer(data.fetch(:epoch_time))
    validate_values!(count: count, period: period, epoch_time: epoch_time)
    @remaining = [limit - count, 0].max
    @reset_in_seconds = period - (epoch_time % period)
    @advisory_status = high_system_load ? 'degraded' : 'nominal'
  rescue KeyError, TypeError, ArgumentError
    raise BackendUnavailable, 'rate-limit status data is unavailable'
  end

  def as_json
    {
      version: 1,
      tier: tier,
      limit: limit,
      remaining: remaining,
      reset_in_seconds: reset_in_seconds,
      advisory_status: advisory_status
    }
  end

  private

  def throttle_for(request)
    data = request.env['rack.attack.throttle_data']
    raise BackendUnavailable, 'rate-limit status data is unavailable' unless data.respond_to?(:find)

    data.find { |name, _values| name.to_s.start_with?(THROTTLE_PREFIX) }
  end

  def validate!(name, data)
    valid_tiers = %w[req/anonymous req/verified_bot]
    return if valid_tiers.include?(name) && data.respond_to?(:fetch)

    raise BackendUnavailable, 'rate-limit status data is unavailable'
  end

  def validate_values!(count:, period:, epoch_time:)
    return if limit >= 0 && count >= 0 && period > 0 && epoch_time >= 0

    raise BackendUnavailable, 'rate-limit status data is unavailable'
  end
end
