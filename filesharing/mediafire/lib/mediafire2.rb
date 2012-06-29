require 'nokogiri'
require 'curl'
require 'v8'
require 'extensions'

module MediaFire
  define_exceptions :LinkError, :Captcha, :NetworkError, :JSError, :ParseError 

  # Download a file from MediaFire to the current directory and return the file path.
  def self.download(url)
    doc = get_doc(url)
    validate_page(doc)
    file_url, file_name = get_file_info(doc)
    download_file(file_url, file_name)
  end
  
private

  def self.get_doc(url)
    body = guard { Curl.get(url, :follow_redirects => true) }.
      with(Curl::Err::CurlError => proc { |e| NetworkError.new("Cannot get page: #{e}") })
    Nokogiri::HTML(body)
  end

  def self.validate_page(doc)
    error_msg = doc.at_css(".error_msg_title").maybe.text and
      raise LinkError.new("Error: #{error_msg.strip}")
    doc.at_css("#form_captcha").blank? or
      raise Captcha.new("Mediafire returns a reCaptcha after too many connections")
    doc.at_css(".dl_options_innerblock") or
      raise ParseError.new("This does not seem a Mediafire file page", :doc => doc)
  end

  def self.get_file_info(doc)
    script = doc.at_css(".dl_startlink script") or
      raise ParseError.new("Cannot find JS element", :doc => doc)
    js_stubs = "var document = {write: function(x) { return x; }};"
    link = guard { V8::Context.new.eval(js_stubs + script.text) }.
      with(V8::JSError => proc { |e| JSError.new("Error evaling JS: #{e}", :doc => doc) })
    file_url = Nokogiri::HTML.fragment(link).at_css("a").maybe["href"] or
      raise ParseError.new("Cannot find link in obfuscated JS", :doc => doc)
    file_name = doc.at_css(".download_file_title").maybe.text.maybe.strip.presence or
      raise ParseError.new("Cannot find file name", :doc => doc)
    [file_url, file_name]
  end

  def self.download_file(file_url, file_name)
    guard { Curl.download_to_file(file_url, file_name, :show_progressbar => true) }.
      with(Curl::Err::CurlError => proc { |e| NetworkError.new("Error downloading file: #{e}") })
  end
end
