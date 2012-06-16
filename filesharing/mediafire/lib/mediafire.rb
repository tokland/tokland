#!/usr/bin/ruby
require 'cgi'
require 'curl'
require 'v8'
require 'nokogiri'
require 'progressbar'

require 'extensions'

module MediaFire
  define_exceptions :LinkError, :Captcha, :NetworkError, :JSError, :ParseError 

  def self.download(url)
    body, headers = wrap { Curl.get_with_headers(url) }.
      with(Curl::Err::CurlError => NetworkError.new("Cannot get main page"))
    headers["Location"] !~ /error.php/ or
      raise LinkError.new("Invalid or deleted file")
    doc = Nokogiri::HTML(body)
    doc.at_css("#form_captcha").blank? or
      raise Captcha.new("Mediafire returns a reCaptcha after some downloads")
    doc.at_css(".homeCallouts").blank? or
      raise LinkError.new("Invalid link")      
      
    script = doc.at_css(".dl_startlink script") or
      raise ParseError.new("Cannot find element '.dl_startlink script'", :body => body)
    js_stubs = "var document = {write: function(x) { return x; }};"
    link = wrap { V8::Context.new.eval(js_stubs + script.text) }.
      with(V8::JSError => JSError.new("Error evaling obfuscated JS", :body => body))
    
    file_url = Nokogiri::HTML.fragment(link).at_css("a").maybe["href"] or
      raise ParseError.new("Cannot find link in obfuscated JS", :body => body)
    filename = CGI.unescape(File.basename(file_url))
    Curl.download_with_progressbar(file_url, filename)
  end
end
