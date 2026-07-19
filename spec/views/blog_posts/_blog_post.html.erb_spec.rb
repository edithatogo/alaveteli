require 'spec_helper'

RSpec.describe 'blog_posts/_blog_post.html.erb', type: :view do
  it 'links to a valid web URL' do
    post = FactoryBot.build(
      :blog_post,
      title: 'Safe post',
      url: 'https://example.com/post'
    )

    render partial: 'blog_posts/blog_post', locals: { blog_post: post }

    expect(rendered).to have_link('Safe post', href: post.url)
  end

  it 'renders an invalid legacy URL as plain text' do
    post = FactoryBot.build(
      :blog_post,
      title: 'Legacy post',
      url: 'javascript:alert(1)'
    )

    render partial: 'blog_posts/blog_post', locals: { blog_post: post }

    expect(rendered).to have_text('Legacy post')
    expect(rendered).not_to have_link('Legacy post')
    expect(rendered).not_to include('javascript:')
  end
end
