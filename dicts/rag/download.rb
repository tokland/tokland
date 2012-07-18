#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'uri'

class Rag
  StartUrl = "http://www.realacademiagalega.org/rag_dicionario/loadNoun.do?id=1"
  
  def self.download(url)
    loop do
      doc = Nokogiri::HTML(RestClient.get(url).to_str)
      noun = doc.at_css(".title .noun").text
      word = noun.lines.map { |s| s.gsub(/[[:space:]]+/, '') }.reject(&:empty?).join("_")
      filename = "#{word}.html"
      definition = doc.at_css(".description").inner_html.strip
      open(filename, "w") { |f| f.write(definition) }
      $stdout.puts(filename)
      anchor = doc.at_css(".next_nouns ul li a") or break
      url = URI.join(StartUrl, anchor["href"]).to_s
    end    
  end
end

if __FILE__ == $0
  Rag.download(ARGV.first || Rag::StartUrl)  
end
