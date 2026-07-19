require 'selenium-webdriver'

# Selenium communicates with its local driver over HTTP, including during the
# process-level cleanup that runs after RSpec has finished.
WebMock.disable_net_connect!(allow_localhost: true)

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1200,800')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
