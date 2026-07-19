require 'spec_helper'

RSpec.describe 'JavaScript asset behavior contracts' do
  def compiled_asset(logical_path)
    Rails.application.assets.find_asset(logical_path).to_s
  end

  shared_examples 'a registered jQuery plugin' do |asset, plugin, registration|
    it "registers $.fn.#{plugin} in #{asset}" do
      source = compiled_asset(asset)

      expect(source).to match(registration)
    end
  end

  include_examples 'a registered jQuery plugin',
                   'application.js',
                   'datepicker',
                   /(?:Datepicker|datepicker)/

  include_examples 'a registered jQuery plugin',
                   'admin.js',
                   'tabs',
                   /widget\(\s*["']ui\.tabs["']/

  include_examples 'a registered jQuery plugin',
                   'admin.js',
                   'sortable',
                   /widget\(\s*["']ui\.sortable["']/

  %w[collapse dropdown tooltip].each do |plugin|
    include_examples 'a registered jQuery plugin',
                     'admin.js',
                     plugin,
                     /\.fn\.#{plugin}\s*=\s*Plugin/
  end

  it 'retains the application datepicker initializer' do
    template = Rails.root.join(
      'app/views/general/_localised_datepicker.html.erb'
    ).read

    expect(template).to include('.datepicker(')
  end

  it 'retains the admin sortable initializer and serialization behavior' do
    source = compiled_asset('admin.js')

    expect(source).to include('list_element.sortable({')
    expect(source).to include("list_element.sortable('serialize'")
  end

  it 'retains representative Bootstrap tooltip and data API behavior' do
    source = compiled_asset('admin.js')

    expect(source).to include("tooltip('show')")
    expect(source).to match(/\[data-toggle=["']dropdown["']\]/)
    expect(source).to match(/\[data-toggle=["']collapse["']\]/)
  end
end
