#!/usr/bin/ruby
require 'cgi'
require 'curl'
require 'v8'
require 'nokogiri'
require 'progressbar'

require './extensions'

class MediaFire
  define_exceptions [:InvalidLink, :Captcha, :ParseError, :NetworkError, :JSError]

  WrappedExceptions = {
    Curl::Err::CurlError => NetworkError,
    Nokogiri::SyntaxError => ParseError, 
    V8::JSError => JSError,
  }

  def self.download(url)
    wrap_exceptions(WrappedExceptions) do
      #body, headers = wrap { Curl.get_with_headers(url) } # explicit exception wrapping 
      body, headers = Curl.get_with_headers(url)
      headers["Location"] != "/error.php?errno=320" or
        raise InvalidLink.new("Invalid or deleted file")
      doc = Nokogiri::HTML(body)
      doc.at_css("#form_captcha").nil? or
        raise Captcha.new("Probably too many connections")
      script = doc.at_css(".dl_startlink script") or
        raise ParseError.new("Cannot find element '.dl_startlink script'")
      js_stubs = "var document = {write: function(x) { return x; }};"
      link = V8::Context.new.eval(js_stubs + script.text)
      
      file_url = Nokogiri::HTML.fragment(link).at_css("a").maybe["href"] or
        raise ParseError.new("Cannot find link in obfuscated JS")
      filename = CGI.unescape(File.basename(file_url))
      Curl.download_with_progressbar(file_url, filename)
    end
  end
end

if __FILE__ == $0
  CommandArgumentsError = Class.new(StandardError)

  exit_codes = {
    CommandArgumentsError => 1,
    MediaFire::InvalidLink => 2,
    MediaFire::ParseError => 3,
    MediaFire::Captcha => 4,
    MediaFire::NetworkError => 5,
    MediaFire::JSError => 6,
  }
  exit(catch_exceptions(exit_codes) do
    mediafire_url = ARGV.first.presence or 
      raise CommandArgumentsError.new("Usage: mediafire-dl URL")  
    file_path = MediaFire.download(mediafire_url)
    $stdout.puts(file_path)
    0
  end)
end
