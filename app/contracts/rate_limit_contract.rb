# frozen_string_literal: true

require 'dry-validation'

class RateLimitContract < Dry::Validation::Contract
  config.validate_keys = true

  params do
    # Status is always scoped to the current request's enforced throttle.
  end
end
