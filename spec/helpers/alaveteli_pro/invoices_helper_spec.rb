require 'spec_helper'

RSpec.describe AlaveteliPro::InvoicesHelper do
  describe '#stripe_document_link' do
    it 'renders a new-window link with opener isolation' do
      link = helper.stripe_document_link(
        'View Invoice',
        'https://invoice.stripe.com/i/invoice_123'
      )

      expect(link).to have_link(
        'View Invoice',
        href: 'https://invoice.stripe.com/i/invoice_123'
      )
      expect(link).to include('target="_blank"')
      expect(link).to include('rel="noopener"')
    end

    it 'returns nil when the validated URL is absent' do
      expect(helper.stripe_document_link('View Invoice', nil)).to be_nil
    end
  end
end
