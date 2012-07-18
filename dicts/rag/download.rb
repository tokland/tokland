#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'uri'

class Rag
  StartUrl = "http://www.realacademiagalega.org/rag_dicionario/loadNoun.do?id=1"
  
  def self.download
    url = StartUrl
    
    loop do
      doc = Nokogiri::HTML(RestClient.get(url).to_str)
      noun = doc.at_css(".title .noun").text
      word = noun.lines.map { |s| s.gsub(/[[:space:]]+/, '') }.reject(&:empty?).join("_")
      filename = "#{word}.html"
      definition = doc.at_css(".description > .definition").inner_html.strip
      open(filename, "w") { |f| f.write(definition) }
      $stderr.puts(filename)
      href = doc.at_css(".next_nouns ul li a")["href"] or break
      url = URI.join(StartUrl, href).to_s
    end    
  end
end

if __FILE__ == $0
  Rag.download  
end
