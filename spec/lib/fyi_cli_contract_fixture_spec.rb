# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'fyi-cli contract fixture manifest' do
  let(:cases) do
    YAML.load_file(Rails.root.join('spec/fixtures/fyi_cli_contract_cases.yml'))
  end

  it 'is deterministic, offline, and covers each server contract category' do
    expect(cases).to all(include('name', 'endpoint', 'request', 'response', 'required_headers'))
    expect(cases.map { |fixture| fixture.fetch('name') }).to contain_exactly(
      'rate-limit-nominal',
      'rate-limit-degraded',
      'bulk-export-unauthorized',
      'bulk-export-invalid-limit',
      'bulk-export-conditional',
      'bulk-export-bounded-ndjson'
    )
    expect(cases.map { |fixture| fixture.fetch('endpoint') }).to all(
      match(%r{\A/api/v1/(rate_limit|bulk_export)\z})
    )
    expect(cases).to all(satisfy { |fixture| fixture.fetch('request').fetch('method') == 'GET' })
    expect(cases).to all(satisfy { |fixture| fixture.fetch('response').fetch('status').is_a?(Integer) })
  end
end
