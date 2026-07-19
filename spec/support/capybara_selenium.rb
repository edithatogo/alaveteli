require 'selenium-webdriver'

SELENIUM_WEBDRIVER_REQUEST = lambda do |uri|
  loopback = ['127.0.0.1', '::1'].include?(uri.host)
  selenium_path = uri.path == '/status' ||
                  uri.path == '/__identify__' ||
                  uri.path.start_with?('/session')
  loopback && selenium_path
end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1200,800')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
