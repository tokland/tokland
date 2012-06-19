require 'spec_helper'

describe MediaFire do
  describe "download" do
    context "when HTML is the expected" do
      it "should return the filename of the downloaded file" do
        Curl.should_receive(:get_with_headers).
          with("http://mediafire.com?1234").
          and_return([read_fixture("normal.html"), {}])
        Curl.should_receive(:download_with_progressbar).
          with("http://205.196.120.108/2yvvyob3w6wg/ss8i5w9df7bxlk5/Logo+quiz+3.1.apk", 
               "Logo quiz 3.1.apk").
          and_return("Logo quiz 3.1.apk")
        MediaFire.download("http://mediafire.com?1234").should == "Logo quiz 3.1.apk"
      end
    end

    context "when server redirects to error page" do
      it "should return the filename of the downloaded file" do
        Curl.should_receive(:get_with_headers).
          with("http://mediafire.com?1234").
          and_return(["", {"Location" => "error.php?errno=320"}])
        lambda do
          MediaFire.download("http://mediafire.com?1234")
        end.should raise_error(MediaFire::LinkError)
      end
    end
    
    context "when HTML is not a Mediafire page" do
      it "should raise exception ParseError" do
        Curl.should_receive(:get_with_headers).
          with("http://somewhere.com").
          and_return([read_fixture("non_mediafire_page.html"), {}])
        lambda do 
          MediaFire.download("http://somewhere.com")
        end.should raise_error(MediaFire::ParseError)
      end
    end

    context "when HTML contains unexpected obfuscated JS code" do
      it "should raise exception ParseError" do
        Curl.should_receive(:get_with_headers).
          with("http://somewhere.com").
          and_return([read_fixture("unexpected_jscode.html"), {}])
        lambda do 
          MediaFire.download("http://somewhere.com")
        end.should raise_error(MediaFire::ParseError)
      end
    end

    context "when HTML asks for a recaptcha" do
      it "should raise exception Captcha" do
        Curl.should_receive(:get_with_headers).
          with("http://mediafire.com?1234").
          and_return([read_fixture("error_recaptcha.html"), {}])
        lambda do 
          MediaFire.download("http://mediafire.com?1234")
        end.should raise_error(MediaFire::Captcha)
      end
    end
  end
end
