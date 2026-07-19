require 'spec_helper'

RSpec.describe 'JavaScript asset browser behavior' do
  include Capybara::DSL

  class AssetBehaviorApp
    def call(env)
      case env.fetch('PATH_INFO')
      when '/admin.js'
        asset('admin.js')
      when '/application.js'
        asset('application.js')
      when '/admin'
        html(admin_fixture)
      when '/application'
        html(application_fixture)
      else
        [404, { 'content-type' => 'text/plain' }, ['Not found']]
      end
    end

    private

    def asset(logical_path)
      source = Rails.application.assets.find_asset(logical_path).to_s
      [200, { 'content-type' => 'application/javascript' }, [source]]
    end

    def html(body)
      [200, { 'content-type' => 'text/html' }, [body]]
    end

    def admin_fixture
      <<~HTML
        <!doctype html>
        <html>
          <body>
            <div id="dropdown" class="dropdown">
              <button id="dropdown-toggle" data-toggle="dropdown">Menu</button>
              <ul class="dropdown-menu"><li>Item</li></ul>
            </div>

            <button id="collapse-toggle" data-toggle="collapse"
                    data-target="#collapsible">Toggle</button>
            <div id="collapsible" class="collapse">Collapsible content</div>

            <button id="tooltip-target" title="Helpful detail">Help</button>

            <div id="tabs">
              <ul>
                <li><a href="#tab-one">One</a></li>
                <li><a href="#tab-two">Two</a></li>
              </ul>
              <div id="tab-one">First panel</div>
              <div id="tab-two">Second panel</div>
            </div>

            <ul id="sortable">
              <li data-id="item_1">One</li>
              <li data-id="item_2">Two</li>
            </ul>

            <script src="/admin.js"></script>
            <script>
              $(function () {
                $('#tooltip-target').tooltip();
                $('#tabs').tabs();
                $('#sortable').sortable();
                document.documentElement.dataset.ready = 'true';
              });
            </script>
          </body>
        </html>
      HTML
    end

    def application_fixture
      <<~HTML
        <!doctype html>
        <html>
          <body>
            <input id="datepicker" type="text">
            <script src="/application.js"></script>
            <script>
              $(function () {
                $('#datepicker').datepicker({ dateFormat: 'yy-mm-dd' });
                document.documentElement.dataset.ready = 'true';
              });
            </script>
          </body>
        </html>
      HTML
    end
  end

  around do |example|
    original_app = Capybara.app
    original_driver = Capybara.current_driver
    Capybara.app = AssetBehaviorApp.new
    Capybara.current_driver = :headless_chrome
    example.run
  ensure
    Capybara.reset_sessions!
    Capybara.current_driver = original_driver
    Capybara.app = original_app
  end

  def wait_for_assets
    expect(page).to have_css('html[data-ready="true"]')
  end

  it 'executes Bootstrap dropdown, collapse, and tooltip interactions' do
    visit '/admin'
    wait_for_assets

    find('#dropdown-toggle').click
    expect(page).to have_css('#dropdown.open')

    find('#collapse-toggle').click
    expect(page).to have_css('#collapsible.in')

    find('#tooltip-target').hover
    expect(page).to have_css('.tooltip.in', text: 'Helpful detail')
  end

  it 'executes jQuery UI tabs and sortable behavior' do
    visit '/admin'
    wait_for_assets

    find('#tabs a', text: 'Two').click
    expect(page).to have_css('#tab-two', text: 'Second panel', visible: true)

    page.execute_script(<<~JS)
      var list = $('#sortable');
      list.append(list.children().first());
      list.sortable('refresh');
    JS
    serialized = page.evaluate_script(
      "$('#sortable').sortable('serialize', { attribute: 'data-id' })"
    )

    expect(serialized).to eq('item[]=2&item[]=1')
  end

  it 'executes the jQuery UI datepicker selection flow' do
    visit '/application'
    wait_for_assets

    find('#datepicker').click
    expect(page).to have_css('.ui-datepicker')

    page.execute_script("$('#datepicker').datepicker('setDate', new Date(2026, 6, 19))")
    expect(find('#datepicker').value).to eq('2026-07-19')
  end
end
