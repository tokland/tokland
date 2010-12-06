#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'

def clean_html(html_path)
  doc = Nokogiri::HTML.parse(open(html_path))
  html = doc.css(".graywin2tr table").css("table")[2..-4].to_s
  STDOUT.write(html)
end

clean_html(ARGV[0])
