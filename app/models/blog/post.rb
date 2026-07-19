# == Schema Information
#
# Table name: blog_posts
#
#  id         :bigint           not null, primary key
#  title      :string
#  url        :string
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Blog::Post < ApplicationRecord
  include Taggable

  def self.admin_title
    'Blog Post'
  end

  validates_presence_of :title, :url
  validates_uniqueness_of :url
  validate :url_is_absolute_http_url

  def safe_url
    url if absolute_http_url?
  end

  def description
    CGI.unescapeHTML(data['description'][0].to_s)
  end

  private

  def absolute_http_url?
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def url_is_absolute_http_url
    return if url.blank? || absolute_http_url?

    errors.add(:url, 'must be an absolute HTTP or HTTPS URL')
  end
end
