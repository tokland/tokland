#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'

fail("Usage: extract_links URL [URL ...]") if ARGV.empty?

ARGV.each do |url|
  doc = Nokogiri::XML(open(url).read)
  hrefs = doc.css("a").map do |link|
    if (href = link.attr("href")) && !href.empty? 
      URI::join(url, href)
    end
  end.compact.uniq 
  STDOUT.puts(hrefs.join("\n"))
end
