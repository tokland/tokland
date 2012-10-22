require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'

module Tv3
  def self.download(url)
    html = open(url).read
    video_id = html.match(/flashvars.videoid = (\d+);/)[1] 
    url = "http://www.tv3.cat/pvideo/FLV_bbd_dadesItem.jsp?idint=#{video_id}"
    doc = Nokogiri::XML(open(url))
    video = doc.css("videos video").max_by do |video|
      video.at_css("qualitat")["ordre"].to_i
    end

    title = doc.at_css("item title").text
    format = video.at_css("format").text
    quality = video.at_css("qualitat").text
    $stderr.puts("title=#{title}, format=#{format}, quality=#{quality}")

    base = "http://www.tv3.cat/pvideo/FLV_bbd_media.jsp"
    url = "#{base}?PROFILE=EVP&ID=#{video_id}&QUALITY=#{quality}&FORMAT=#{format}"
    doc = Nokogiri::XML(open(url))

    # rtmp://mp4-500-strfs.fplive.net/mp4-500-str/mp4:g/tvcatalunya/5/2/1350313296225.mp4
    rtmp_url = doc.at_css("item media").text
    $stderr.puts("rtmp_url=#{rtmp_url}")
    u = URI.parse(rtmp_url) 
    sp = u.path.split(File::SEPARATOR)
    app = sp[1]
    tc_url = URI.join(u, sp.take(2).join(File::SEPARATOR)).to_s 
    playpath = URI.join(u, sp.drop(2).join(File::SEPARATOR)).to_s
    video_path = [title.gsub("/", "-"), format.downcase].join(".")

    command = [
      ["rtmpdump"],
      ["--protocol", u.scheme],
      ["--host", u.host],
      ["--tcUrl", tc_url],
      ["--app", app],
      ["--playpath", playpath],
      ["-o", "\"#{video_path}\""],
    ].flatten(1).join(" ")
    $stderr.puts("command: #{command}")
    system(command)
    video_path
  end
end

if __FILE__ == $0
  ARGV.each { |url| puts(Tv3.download(url)) }  
end
