require 'spec_helper'

RSpec.describe 'admin asset compatibility' do
  subject(:stylesheet) { Rails.application.assets.find_asset('admin.css').to_s }

  it 'compiles the admin stylesheet' do
    expect(stylesheet).to be_present
  end

  it 'retains the Bootstrap 2 contracts used by admin templates' do
    selectors = %w[
      .admin\ .span12
      .admin\ .offset5
      .admin\ .control-group
      .admin\ .form-horizontal\ .controls
      .admin\ .navbar-inner
      .admin\ .navbar\ .brand
      .admin\ .btn-mini
      .admin\ .accordion-group
      .admin\ .accordion-inner
      .admin\ .alert-error
      .admin\ .icon-eye-open
      .admin\ .icon-lock
    ]

    selectors.each do |selector|
      expect(stylesheet).to include(selector), "expected admin.css to define #{selector}"
    end
  end

  it 'compiles the legacy Bootstrap JavaScript entry points' do
    assets = %w[
      bootstrap-collapse.js
      bootstrap-dropdown.js
      bootstrap-popover.js
      bootstrap-tab.js
      bootstrap-tooltip.js
    ]

    assets.each do |logical_path|
      expect(Rails.application.assets.find_asset(logical_path)).to be_present
    end
  end
end
