#!/usr/bin/ruby
require 'cgi'
require 'curl'
require 'v8'
require 'nokogiri'
require 'progressbar'
require 'nestegg'

require './extensions'

class Object
  def wrap_exceptions(relations)
    begin
      yield
    rescue => exc
      raise(*relations.map_detect do |source, dest|
        if exc.is_a?(source)
          dest.new("ERROR: #{[exc.class.name, exc.to_s].uniq.join(': ')}")
        end
      end)
    end
  end
end

class MediaFire
  [:CaptchaChallenge, :ParseError, :NetworkError, :JavascriptError].each do |name| 
    self.const_set(name, Class.new(StandardError)) #do
      #include Nestegg::NestingException
    #end)
  end

  WrappedExceptions = {
    Curl::Err::CurlError => NetworkError,
    V8::JSError => JavascriptError,
  }

  def self.download(url)
    wrap_exceptions(WrappedExceptions) do
      html = Curl.get(url).body_str
      doc = Nokogiri::HTML(html)
      doc.at_css("#form_captcha").nil? or
        raise CaptchaChallenge.new("Probably too many connections") 
      script = doc.at_css(".dl_startlink script") or
        raise ParseError.new("Cannot find element '.dl_startlink script'") 
      js_stubs = "var document = {write: function(x) { return x; }};"
      script = V8::Context.new.eval(js_stubs + script.text)
      link = Nokogiri::HTML::fragment(script)
      
      file_url = link.at_css("a").maybe["href"] or
        raise ParseError.new("Cannot find link in JS obfuscation code")
      filename = CGI::unescape(File.basename(file_url))
      Curl.download_with_progressbar(filename, file_url)
    end
  end
end

if __FILE__ == $0
  CommandArgumentsError = Class.new(StandardError)

  ExitCodes = {
    CommandArgumentsError => 1,
    MediaFire::ParseError => 2,
    MediaFire::CaptchaChallenge => 3,
    MediaFire::NetworkError => 4,
    MediaFire::JavascriptError => 5,
  }

  exit(catch_exceptions(ExitCodes) do
    mediafire_url = ARGV.first or 
      raise CommandArgumentsError.new("Usage: mediafire-dl URL")  
    file_path = MediaFire.download(mediafire_url)
    $stdout.puts(file_path)
  end)
end
