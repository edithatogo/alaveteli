require 'spec_helper'

RSpec.describe 'alaveteli_pro/invoices/_invoice' do
  let(:invoice) do
    double(
      created: Date.new(2024, 7, 29),
      number: 'INV-123',
      amount_due: 1000,
      paid?: paid,
      open?: open,
      receipt_url: receipt_url,
      hosted_invoice_url: hosted_invoice_url
    )
  end
  let(:paid) { false }
  let(:open) { false }
  let(:receipt_url) { nil }
  let(:hosted_invoice_url) { nil }

  before do
    allow(view).to receive(:format_currency).and_return('$10.00')
  end

  it 'renders a trusted receipt link' do
    allow(invoice).to receive(:paid?).and_return(true)
    allow(invoice).to receive(:receipt_url).
      and_return('https://pay.stripe.com/receipts/receipt_123')

    render(
      partial: 'alaveteli_pro/invoices/invoice',
      locals: { invoice: invoice }
    )

    expect(rendered).to have_link(
      'View Receipt', href: 'https://pay.stripe.com/receipts/receipt_123'
    )
  end

  it 'omits the receipt link when the URL is absent or invalid' do
    allow(invoice).to receive(:paid?).and_return(true)

    render(
      partial: 'alaveteli_pro/invoices/invoice',
      locals: { invoice: invoice }
    )

    expect(rendered).not_to have_link('View Receipt')
  end

  it 'renders a trusted hosted invoice link' do
    allow(invoice).to receive(:open?).and_return(true)
    allow(invoice).to receive(:hosted_invoice_url).
      and_return('https://invoice.stripe.com/i/invoice_123')

    render(
      partial: 'alaveteli_pro/invoices/invoice',
      locals: { invoice: invoice }
    )

    expect(rendered).to have_link(
      'View Invoice and Pay', href: 'https://invoice.stripe.com/i/invoice_123'
    )
  end

  it 'omits the hosted invoice link when the URL is absent or invalid' do
    allow(invoice).to receive(:open?).and_return(true)

    render(
      partial: 'alaveteli_pro/invoices/invoice',
      locals: { invoice: invoice }
    )

    expect(rendered).not_to have_link('View Invoice and Pay')
  end
end
