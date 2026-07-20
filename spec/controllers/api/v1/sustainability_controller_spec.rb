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
    it 'returns the rate-limiting information' do
      get :rate_limit
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['tier']).to eq('anonymous')
      expect(json['limit']).to eq(10)
      expect(json['remaining']).to eq(10)
      expect(json['advisory_status']).to eq('nominal')
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

      it 'returns 200 and streams NDJSON data' do
        get :bulk_export, params: {
          limit: 1,
          since: export_started_at.iso8601(6)
        }

        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq('application/x-ndjson')
        expect_private_revalidation_cache_control
        expect(response.headers['ETag']).to be_present
        expect(response.headers['Last-Modified']).to be_blank
        expect(response.headers['Content-Disposition']).to eq(
          'attachment; filename="requests_export.ndjson"'
        )
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
        expect(response.headers['Last-Modified']).to be_blank
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
        get :bulk_export, params: { limit: 1 }
        consume_response_body
        original_etag = response.headers['ETag']
        request.headers['If-None-Match'] = original_etag
        info_request.update!(title: 'Changed request')

        get :bulk_export, params: { limit: 1 }
        consume_response_body
        changed_etag = response.headers['ETag']

        expect(response.status).to eq(200)
        expect(changed_etag).not_to eq(original_etag)

        request.headers['If-None-Match'] = changed_etag
        info_request.delete
        get :bulk_export, params: { limit: 1 }
        consume_response_body

        expect(response.status).to eq(200)
        expect(response.headers['ETag']).not_to eq(changed_etag)
      end

      it 'returns a new representation after authority translation mutation' do
        get :bulk_export, params: { limit: 1 }
        consume_response_body
        original_etag = response.headers['ETag']
        request.headers['If-None-Match'] = original_etag
        selected_translation = info_request.public_body.translations.find_by(
          locale: AlaveteliLocalization.locale
        ) || info_request.public_body.translations.first
        selected_translation.update!(
          name: 'Changed authority'
        )

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
