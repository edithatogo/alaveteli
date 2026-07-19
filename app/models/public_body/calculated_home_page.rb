# Guess the home page based on the request email domain.
module PublicBody::CalculatedHomePage
  extend ActiveSupport::Concern

  included do
    validate :public_body_web_urls_are_safe
  end

  class_methods do
    def excluded_calculated_home_page_domains
      @excluded_calculated_home_page_domains ||= Domains.webmail_providers
    end

    def excluded_calculated_home_page_domains=(domains)
      @excluded_calculated_home_page_domains = domains
    end

    def safe_web_url(value)
      return if value.blank?

      uri = URI.parse(value)
      return unless uri.is_a?(URI::HTTP)
      return unless %w[http https].include?(uri.scheme&.downcase)
      return unless uri.host.present?
      return if uri.userinfo.present?

      value
    rescue URI::InvalidURIError
      nil
    end
  end

  def calculated_home_page
    @calculated_home_page ||= calculated_home_page!
  end

  def safe_web_url(value)
    self.class.safe_web_url(value)
  end

  private

  # Ensure known home page has a full URL or guess if not known.
  def calculated_home_page!
    home_page.present? ? ensure_home_page_protocol : guess_home_page
  end

  # Ensure the home page has the HTTP protocol at the start of the URL
  def ensure_home_page_protocol
    return unless home_page.present?

    candidate = home_page.match?(/\Ahttps?:\/\//i) ? home_page : "https://#{home_page}"
    safe_web_url(candidate)
  end

  # Guess the home page from the request address email domain.
  def guess_home_page
    return unless request_email_domain
    return if excluded_calculated_home_page_domain?(request_email_domain)

    "https://www.#{request_email_domain}"
  end

  def excluded_calculated_home_page_domain?(domain)
    self.class.excluded_calculated_home_page_domains.include?(domain)
  end

  def public_body_web_urls_are_safe
    if web_url_requires_validation?(:home_page) &&
       home_page.present? && ensure_home_page_protocol.blank?
      errors.add(:home_page, _("The URL doesn't look like a valid web address"))
    end

    { publication_scheme: publication_scheme,
      disclosure_log: disclosure_log }.each do |attribute, value|
      next unless web_url_requires_validation?(attribute)
      next if value.blank? || safe_web_url(value)

      errors.add(attribute, _("The URL doesn't look like a valid web address"))
    end
  end

  def web_url_requires_validation?(attribute)
    new_record? || will_save_change_to_attribute?(attribute)
  end
end
