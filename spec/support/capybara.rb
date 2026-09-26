Capybara.default_driver    = :selenium_chrome
Capybara.javascript_driver = :selenium_chrome

Capybara.register_driver :selenium_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')
  options.binary = '/usr/bin/chromium'

  service = Selenium::WebDriver::Service.chrome(path: '/usr/bin/chromedriver')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end
