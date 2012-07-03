require 'nokogiri'
require 'curl'
require 'v8'
require 'extensions'

module MediaFire
  define_exceptions :LinkError, :Captcha, :NetworkError, :JSError, :ParseError 

  # Download a file from MediaFire to the current directory and return the file path.
  def self.download(url)
    doc = lets "Get the DOM of the page" do
      body = guard { Curl.get(url, :follow_redirects => true) }.
        with(Curl::Err::CurlError => proc { |e| NetworkError.new("Cannot get page: #{e}") })
      Nokogiri::HTML(body)
    end

    lets "Validate that we got a MediaFire page with a file to download" do
      error_msg = doc.at_css(".error_msg_title").maybe.text and
        raise LinkError.new("Error: #{error_msg.strip}")
      doc.at_css("#form_captcha").blank? or
        raise Captcha.new("Mediafire returns a reCaptcha after too many connections")
      doc.at_css(".dl_options_innerblock") or
        raise ParseError.new("This does not seem a Mediafire file page", :doc => doc)
    end

    file_name, file_url = lets "Get the file URL and its name" do 
      script = doc.at_css(".dl_startlink script") or
        raise ParseError.new("Cannot find JS element", :doc => doc)
      js_stubs = "var document = {write: function(x) { return x; }};"
      link = guard { V8::Context.new.eval(js_stubs + script.text) }.
        with(V8::JSError => proc { |e| JSError.new("Error evaling JS: #{e}", :doc => doc) })
      file_url = Nokogiri::HTML.fragment(link).at_css("a").maybe["href"] or
        raise ParseError.new("Cannot find link in obfuscated JS", :doc => doc)
      file_name = doc.at_css(".download_file_title").maybe.text.maybe.strip.presence or
        raise ParseError.new("Cannot find file name", :doc => doc)
      [file_name, file_url]
    end
   
    lets "finally download the file" do
      guard { Curl.download_to_file(file_url, file_name, :show_progressbar => true) }.
        with(Curl::Err::CurlError => proc { |e| NetworkError.new("Error downloading file: #{e}") })
    end
  end
end
