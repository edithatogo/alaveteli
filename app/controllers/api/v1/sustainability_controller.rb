class Api::V1::SustainabilityController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :html_response, raise: false
  skip_after_action :inject_rate_limit_headers, only: :rate_limit

  def rate_limit
    BotTrafficMetrics.increment(:rate_limit_requests)

    contract = RateLimitContract.new.call(rate_limit_params)
    if contract.failure?
      response.headers['Cache-Control'] = 'no-store'
      render(
        json: { error: 'Invalid parameters', details: contract.errors.to_h },
        status: :unprocessable_entity
      )
      return
    end

    status = RackAttackRateLimitStatus.new(request: request)
    set_rate_limit_headers(status)
    render json: status.as_json
  rescue RackAttackRateLimitStatus::BackendUnavailable
    response.headers['Cache-Control'] = 'no-store'
    render(
      json: {
        version: 1,
        error: 'rate_limit_status_unavailable',
        advisory_status: 'degraded'
      },
      status: :service_unavailable
    )
  end

  def bulk_export
    contract = BulkExportContract.new.call(params.permit(:limit, :since).to_h)
    if contract.failure?
      render(
        json: { error: 'Invalid parameters', details: contract.errors.to_h },
        status: :unprocessable_entity
      )
      return
    end

    # Only allow verified bots to access bulk export
    token = request.env['HTTP_X_FYI_BOT_TOKEN']
    is_verified = token.present? && token == ENV['FYI_BOT_TOKEN']

    unless is_verified
      BotTrafficMetrics.increment(:bulk_export_unauthorized)
      render(
        json: {
          error: 'Unauthorized. Bulk export requires a valid verified bot token.'
        },
        status: :unauthorized
      )
      return
    end

    BotTrafficMetrics.increment(:bulk_export_requests)

    export_since = parsed_since(contract.to_h[:since])
    snapshot = BulkExportSnapshot.new(
      limit: contract.to_h[:limit],
      since: export_since
    )
    response.headers['ETag'] = %Q("#{snapshot.etag}")

    if request.fresh?(response)
      snapshot.close!
      head :not_modified
      apply_private_revalidation_cache_control
      return
    end

    response.headers['Content-Type'] = 'application/x-ndjson'
    response.headers['Content-Disposition'] = 'attachment; filename="requests_export.ndjson"'

    self.response_body = snapshot
    apply_private_revalidation_cache_control
  end

  private

  def apply_private_revalidation_cache_control
    response.cache_control[:private] = true
    response.cache_control[:no_cache] = true
    response.cache_control[:extras] =
      Array(response.cache_control[:extras]) | ['private']
  end

  def rate_limit_params
    params.to_unsafe_h.except('controller', 'action', 'format')
  end

  def set_rate_limit_headers(status)
    response.headers['Cache-Control'] = 'no-store'
    response.headers['RateLimit-Limit'] = status.limit.to_s
    response.headers['RateLimit-Remaining'] = status.remaining.to_s
    response.headers['RateLimit-Reset'] = status.reset_in_seconds.to_s
    response.headers['X-Advisory-Status'] = status.advisory_status
  end

  def parsed_since(value)
    return if value.blank?

    Time.zone.parse(value)
  end
end
