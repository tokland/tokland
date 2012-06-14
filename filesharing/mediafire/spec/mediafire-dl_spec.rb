require 'rspec'
require 'mediafire-dl'

describe MediaFire do
  describe "download" do
    context "when HTML is the expected" do
      it "should return the filename of the downloaded file" do
        html = File.read(File.join("spec/fixtures/normal.html"))
        Curl.should_receive(:get_with_headers).with("http://mediafire.com?1234").
          and_return([html, {}])
        Curl.should_receive(:download_with_progressbar).
          with("http://205.196.120.108/2yvvyob3w6wg/ss8i5w9df7bxlk5/Logo+quiz+3.1.apk", 
               "Logo quiz 3.1.apk").
          and_return("Logo quiz 3.1.apk")
        MediaFire.download("http://mediafire.com?1234").should == "Logo quiz 3.1.apk"
      end
    end
    
    context "when HTML asks for a recaptcha" do
      it "should raise exception Captcha" do
        html = File.read(File.join("spec/fixtures/error_recaptcha.html"))
        Curl.should_receive(:get_with_headers).
          with("http://mediafire.com?1234").and_return([html, {}])
        lambda do 
          MediaFire.download("http://mediafire.com?1234")
        end.should raise_error(MediaFire::Captcha)
      end
    end
  end
end
