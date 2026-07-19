module AlaveteliPro::InvoicesHelper
  def stripe_document_link(label, url)
    return unless url

    link_to label, url, target: '_blank', rel: 'noopener'
  end
end
