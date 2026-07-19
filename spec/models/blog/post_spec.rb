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

require 'spec_helper'
require 'models/concerns/taggable'

RSpec.describe Blog::Post, type: :model do
  it_behaves_like 'concerns/taggable', :blog_post

  let(:post) { FactoryBot.build(:blog_post) }

  describe 'validations' do
    specify { expect(post).to be_valid }

    it 'requires title' do
      post.title = nil
      expect(post).not_to be_valid
    end

    it 'requires url' do
      post.url = nil
      expect(post).not_to be_valid
    end

    it 'requires unique url' do
      FactoryBot.create(:blog_post, url: 'http://example.com/blog_post_1')
      post.url = 'http://example.com/blog_post_1'
      expect(post).not_to be_valid
    end

    it 'accepts absolute HTTP and HTTPS URLs' do
      %w[http://example.com/post https://example.com/post].each do |url|
        post.url = url
        expect(post).to be_valid
      end
    end

    it 'rejects non-web, relative, and malformed URLs' do
      ['javascript:alert(1)', '//example.com/post', '/post', 'not a url'].
        each do |url|
          post.url = url
          expect(post).not_to be_valid
        end
    end
  end

  describe '#safe_url' do
    it 'returns a valid web URL' do
      post.url = 'https://example.com/post'
      expect(post.safe_url).to eq('https://example.com/post')
    end

    it 'does not expose an invalid legacy URL' do
      post.url = 'javascript:alert(1)'
      expect(post.safe_url).to be_nil
    end
  end

  describe '#description' do
    subject { post.description }

    let(:description) { 'Post description' }

    let(:post) do
      FactoryBot.build(
        :blog_post, data: { 'description' => [description, 'secondary'] }
      )
    end

    it 'returns first description from data' do
      is_expected.to eq('Post description')
    end

    context 'when description contains escaped HTML entities' do
      let(:description) { 'Foo &amp; Bar' }

      it 'unescapes HTML entities' do
        is_expected.to eq('Foo & Bar')
      end
    end
  end
end
