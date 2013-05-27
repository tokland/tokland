require 'nokogiri'
require 'capybara'
require 'capybara/webkit'
require 'RMagick'

class CapybaraBrowser
  include Capybara::DSL
  
  def initialize(options = {})
    options = {:driver => :selenium, :default_wait_time => 10}.merge(options)
    Capybara.current_driver = options.fetch(:driver)
    Capybara.default_wait_time = options.fetch(:default_wait_time)
    Capybara.run_server = false
  end
end

browser = CapybaraBrowser.new(:driver => :selenium)
url = "file:// " + File.join(Dir.pwd, "functional-ruby.html")
browser.visit(url)
brwoser_window = Capybara.current_session.driver.browser.manage.window
brwoser_window.resize_to(1440, 1080+106)
pages = Integer(browser.page.evaluate_script("getPagesCount()"))

image_paths = (0...pages).map do |page|
  browser.page.execute_script("goToStaticPage(#{page.to_json})")
  image_path = ".page-#{page}.png"
  browser.page.save_screenshot(image_path)
  image_path
end

image_list = Magick::ImageList.new(*image_paths)
image_list.write("functional-ruby.pdf") 
