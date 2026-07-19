module AlaveteliPro
  ##
  # This class adds wraps a Stripe::Invoice object to customise behaviour
  # and to add useful helper methods.
  #
  class Invoice < SimpleDelegator
    STRIPE_URL_HOSTS = {
      hosted_invoice_url: %w[invoice.stripe.com],
      receipt_url: %w[pay.stripe.com]
    }.freeze

    # state
    def open?
      status == 'open'
    end

    def paid?
      status == 'paid' && amount_paid > 0
    end

    # attributes
    def created
      Time.at(super).to_date
    end

    # charge
    def charge
      charge_id = __getobj__.charge
      @charge ||= Stripe::Charge.retrieve(charge_id) if charge_id
    end

    def hosted_invoice_url
      trusted_stripe_url(
        :hosted_invoice_url,
        __getobj__.hosted_invoice_url
      )
    end

    def receipt_url
      trusted_stripe_url(:receipt_url, charge&.receipt_url)
    end

    private

    def trusted_stripe_url(attribute, value)
      uri = URI.parse(value.to_s)
      return unless uri.is_a?(URI::HTTPS)
      return unless uri.port == 443
      return unless STRIPE_URL_HOSTS.fetch(attribute).include?(uri.host)

      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def method_missing(*args)
      # Forward missing methods such as #coupon= as on a blank subscription
      # this wouldn't be delegated due to how Stripe::APIResource instances
      # use meta programming to dynamically define setting methods.
      __getobj__.public_send(*args)
    end
  end
end
