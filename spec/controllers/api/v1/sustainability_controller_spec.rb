require 'spec_helper'

RSpec.describe Api::V1::SustainabilityController, type: :controller do
  def consume_response_body
    body = response.body
    return body if body.is_a?(String)

    body.each.to_a.join
  end

  def cache_control_directives
    response.headers.fetch('Cache-Control').split(',').map(&:strip)
  end

  def expect_private_revalidation_cache_control
    directives = cache_control_directives

    expect(directives.tally).to include('private' => 1, 'no-cache' => 1)
    expect(directives).not_to include('public')
  end

  describe 'GET rate_limit' do
    def throttle_data(name:, limit:, count:, period: 60, epoch_time: 125)
      {
        name => {
          limit: limit,
          count: count,
          period: period,
          epoch_time: epoch_time
        }
      }
    end

    before do
      allow(Rack::Attack).to receive(:high_system_load?).and_return(false)
    end

    it 'reports the anonymous throttle data used by Rack::Attack' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 10, count: 3
      )

      get :rate_limit

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['version']).to eq(1)
      expect(json['tier']).to eq('anonymous')
      expect(json['limit']).to eq(10)
      expect(json['remaining']).to eq(7)
      expect(json['reset_in_seconds']).to eq(55)
      expect(json['advisory_status']).to eq('nominal')
    end

    it 'reports the verified bot throttle tier' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/verified_bot', limit: 100, count: 4
      )

      get :rate_limit

      json = JSON.parse(response.body)
      expect(json).to include(
        'tier' => 'verified_bot',
        'limit' => 100,
        'remaining' => 96
      )
    end

    it 'uses one snapshot for the JSON body and rate-limit headers' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 2, count: 2
      )
      expect(Rack::Attack).to receive(:high_system_load?).once.and_return(true)

      get :rate_limit

      json = JSON.parse(response.body)
      expect(response.headers).to include(
        'Cache-Control' => 'no-store',
        'RateLimit-Limit' => json['limit'].to_s,
        'RateLimit-Remaining' => json['remaining'].to_s,
        'RateLimit-Reset' => json['reset_in_seconds'].to_s,
        'X-Advisory-Status' => json['advisory_status']
      )
      expect(json['advisory_status']).to eq('degraded')
    end

    it 'does not access limiter cache while recording endpoint metrics' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 10, count: 1
      )
      expect(Rack::Attack).not_to receive(:cache)
      expect(BotTrafficMetrics).to receive(:increment).
        with(:rate_limit_requests).
        and_call_original

      get :rate_limit

      expect(response).to have_http_status(:ok)
    end

    it 'returns sanitized degraded output when throttle evidence is unavailable' do
      request.env.delete('rack.attack.throttle_data')

      get :rate_limit

      expect(response).to have_http_status(:service_unavailable)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(JSON.parse(response.body)).to eq(
        'version' => 1,
        'error' => 'rate_limit_status_unavailable',
        'advisory_status' => 'degraded'
      )
    end

    it 'returns sanitized degraded output for a zero-length period' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 10, count: 1, period: 0
      )

      get :rate_limit

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)).to eq(
        'version' => 1,
        'error' => 'rate_limit_status_unavailable',
        'advisory_status' => 'degraded'
      )
    end

    it 'returns sanitized degraded output for negative throttle values' do
      invalid_values = [
        { limit: -1, count: 0, period: 60, epoch_time: 125 },
        { limit: 10, count: -1, period: 60, epoch_time: 125 },
        { limit: 10, count: 0, period: -1, epoch_time: 125 },
        { limit: 10, count: 0, period: 60, epoch_time: -1 }
      ]

      invalid_values.each do |values|
        request.env['rack.attack.throttle_data'] = throttle_data(
          name: 'req/anonymous', **values
        )

        get :rate_limit

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include(
          'error' => 'rate_limit_status_unavailable',
          'advisory_status' => 'degraded'
        )
      end
    end

    it 'rejects all query parameters, including the former ip parameter' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 10, count: 1
      )

      get :rate_limit, params: { ip: '192.0.2.1' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(JSON.parse(response.body)['error']).to eq('Invalid parameters')
    end

    it 'does not hide unexpected implementation failures' do
      request.env['rack.attack.throttle_data'] = throttle_data(
        name: 'req/anonymous', limit: 10, count: 1
      )
      allow(RackAttackRateLimitStatus).to receive(:new).
        and_raise(RuntimeError, 'unexpected')

      expect { get :rate_limit }.to raise_error(RuntimeError, 'unexpected')
    end
  end

  describe 'GET bulk_export' do
    context 'without a token' do
      it 'returns unauthorized error' do
        get :bulk_export
        expect(response.status).to eq(401)
      end
    end

    context 'with a valid verified bot token' do
      let!(:export_started_at) { 1.second.ago }
      let!(:info_request) { FactoryBot.create(:info_request) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).
          with('FYI_BOT_TOKEN').
          and_return('valid_secret_token')
        request.env['HTTP_X_FYI_BOT_TOKEN'] = 'valid_secret_token'
      end

      def export_row(title: info_request.title, public_body_name: info_request.public_body.name)
        {
          id: info_request.id,
          title: title,
          url_title: info_request.url_title,
          created_at: info_request.created_at,
          updated_at: info_request.updated_at,
          status: 'waiting_response',
          public_body_name: public_body_name,
          public_body_url_name: info_request.public_body.url_name
        }
      end

      it 'returns 200 and streams NDJSON data' do
        get :bulk_export, params: {
          limit: 1,
          since: export_started_at.iso8601(6)
        }

        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq('application/x-ndjson')
        expect_private_revalidation_cache_control
        expect(response.headers['ETag']).to be_present
        lines = consume_response_body.split("\n")
        expect(lines.size).to eq(1)
        json = JSON.parse(lines.first)
        expect(json['title']).to eq(info_request.title)
        expect(json.keys).to contain_exactly(
          'id',
          'title',
          'url_title',
          'created_at',
          'updated_at',
          'status',
          'public_body_name',
          'public_body_url_name'
        )
      end

      it 'returns 304 when the private export ETag matches' do
        get :bulk_export, params: { limit: 1 }
        consume_response_body
        etag = response.headers['ETag']
        request.headers['If-None-Match'] = etag

        get :bulk_export, params: { limit: 1 }

        expect(response.status).to eq(304)
        expect(response.body).to be_empty
        expect_private_revalidation_cache_control
      end

      it 'hashes the exact response body bytes' do
        get :bulk_export, params: { limit: 1 }
        body = consume_response_body
        digest = Digest::SHA256.hexdigest(body)

        expect(response.headers['ETag']).to eq(%Q("#{digest}"))
        expect(response.headers['Last-Modified']).to be_blank
      end

      it 'closes the unused snapshot on an ETag 304' do
        snapshot = instance_double(
          BulkExportSnapshot,
          etag: 'unchanged',
          close!: nil
        )
        allow(BulkExportSnapshot).to receive(:new).and_return(snapshot)
        request.headers['If-None-Match'] = '"unchanged"'

        get :bulk_export, params: { limit: 1 }

        expect(response.status).to eq(304)
        expect(snapshot).to have_received(:close!)
      end

      it 'returns a new representation after request mutation and deletion' do
        rows = [export_row]
        allow(BulkExportStreamer).to receive(:new).and_return(rows)

        get :bulk_export, params: { limit: 1 }
        consume_response_body
        original_etag = response.headers['ETag']
        request.headers['If-None-Match'] = original_etag
        rows.first[:title] = 'Changed request'

        get :bulk_export, params: { limit: 1 }
        consume_response_body
        changed_etag = response.headers['ETag']

        expect(response.status).to eq(200)
        expect(changed_etag).not_to eq(original_etag)

        request.headers['If-None-Match'] = changed_etag
        rows.clear
        get :bulk_export, params: { limit: 1 }
        consume_response_body

        expect(response.status).to eq(200)
        expect(response.headers['ETag']).not_to eq(changed_etag)
      end

      it 'returns a new representation after authority translation mutation' do
        rows = [export_row]
        allow(BulkExportStreamer).to receive(:new).and_return(rows)

        get :bulk_export, params: { limit: 1 }
        consume_response_body
        original_etag = response.headers['ETag']
        request.headers['If-None-Match'] = original_etag
        rows.first[:public_body_name] = 'Changed authority'

        get :bulk_export, params: { limit: 1 }
        consume_response_body

        expect(response.status).to eq(200)
        expect(response.headers['ETag']).not_to eq(original_etag)
      end

      it 'returns a new representation when date-sensitive status changes' do
        current_status = 'waiting_response'
        allow(BulkExportStreamer).to receive(:new) do
          [{ id: info_request.id, status: current_status }]
        end

        get :bulk_export, params: { limit: 1 }
        consume_response_body
        original_etag = response.headers['ETag']
        request.headers['If-None-Match'] = original_etag
        current_status = 'waiting_response_overdue'

        get :bulk_export, params: { limit: 1 }
        consume_response_body

        expect(response.status).to eq(200)
        expect(response.headers['ETag']).not_to eq(original_etag)
      end

      it 'does not expose validators to unauthenticated requests' do
        request.env.delete('HTTP_X_FYI_BOT_TOKEN')

        get :bulk_export, params: { limit: 1 }

        expect(response.status).to eq(401)
        expect(response.headers['ETag']).to be_blank
      end

      it 'rejects invalid limit values' do
        get :bulk_export, params: { limit: 0 }

        expect(response.status).to eq(422)
      end

      it 'rejects invalid since values' do
        get :bulk_export, params: { since: 'not-a-date' }

        expect(response.status).to eq(422)
      end
    end
  end
end
