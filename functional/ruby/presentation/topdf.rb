require 'nokogiri'
require 'capybara'
require 'capybara/webkit'
require 'RMagick'
require 'webrick'

class CapybaraBrowser
  include Capybara::DSL
  
  def initialize(options = {})
    options = {:driver => :selenium, :default_wait_time => 10}.merge(options)
    Capybara.current_driver = options.fetch(:driver)
    Capybara.default_wait_time = options.fetch(:default_wait_time)
    Capybara.run_server = false
  end
end

port = 25080
server = WEBrick::HTTPServer.new(:Port => port, :DocumentRoot => Dir.pwd)
thread = Thread.new { server.start }
stop_server = proc do
  server.shutdown
  thread.join
end
trap("INT", &stop_server)

browser = CapybaraBrowser.new(:driver => :selenium)
url = "http://localhost:#{port}/functional-ruby.html"
browser.visit(url)
window = Capybara.current_session.driver.browser.manage.window
window.resize_to(1440, 1080+106)
pages = Integer(browser.page.evaluate_script("getPagesCount()"))

image_paths = 0.upto(pages).map do |page|
  browser.page.execute_script("goToStaticPage(#{page.to_json})")
  image_path = ".page-#{page}.png"
  browser.page.save_screenshot(image_path)
  image_path
end

image_list = Magick::ImageList.new(*image_paths)
image_list.write("functional-ruby.pdf") 
stop_server.call
