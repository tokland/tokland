require 'nokogiri'
require 'curl'
require 'cgi'
require 'v8'

require 'extensions'

module MediaFire
  define_exceptions :LinkError, :Captcha, :NetworkError, :JSError, :ParseError 

  # Download a file from MediaFire to the current directory and return the file path.
  def self.download(url)
    body, headers = catch { Curl.get_with_headers(url) }.
      on(Curl::Err::CurlError => NetworkError.new("Cannot get main page"))
    headers["Location"] !~ /error.php/ or
      raise LinkError.new("Invalid or deleted file")
    doc = Nokogiri::HTML(body)
    doc.at_css("#form_captcha").blank? or
      raise Captcha.new("Mediafire returns a reCaptcha after some downloads")
    doc.at_css(".dl_options_innerblock") or
      raise ParseError.new("That does not seem like a Mediafire file page")
      
    script = doc.at_css(".dl_startlink script") or
      raise ParseError.new("Cannot find JS element", :body => body)
    js_stubs = "var document = {write: function(x) { return x; }};"
    link = catch { V8::Context.new.eval(js_stubs + script.text) }.
      on(V8::JSError => JSError.new("Error evaling JS", :body => body))
    
    file_url = Nokogiri::HTML.fragment(link).at_css("a").maybe["href"] or
      raise ParseError.new("Cannot find link in obfuscated JS", :body => body)
    file_name = CGI.unescape(File.basename(file_url))
    Curl.download_with_progressbar(file_url, file_name)
  end
end
