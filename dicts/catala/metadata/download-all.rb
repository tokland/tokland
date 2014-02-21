require 'rest-client'
require 'fileutils'
require 'nokogiri'

module Diccionaris
  IndexUrlTemplate = 
    "http://www.diccionari.cat/cgi-bin/AppDLC3.exe?APP=SEGUENTS&P=%{index}"
    
  def self.download_all(output_directory)
    FileUtils.mkdir_p(output_directory)
    start_index_url = IndexUrlTemplate % {index: 145066} # last: 1547411
    index_url = start_index_url
     
    loop do
      index_doc = Nokogiri::HTML(RestClient.get(index_url))
      index_doc.css(".CentreTextTD .LLISTA_D").each do |word_link|
        word_url = word_link.attribute("href").value
        index = word_url[/GECART=(\d+)/, 1] or next #fail("No index in word: #{word_url}")
        path = File.join(output_directory, "#{index}.html")
        if File.exists?(path) && File.size(path) > 0
          $stderr.puts("#{path}: exists")
        else
          word_doc = Nokogiri::HTML(RestClient.get(word_url))
          word_contents = word_doc.css("td.CentreTextTD > table").to_html
          File.write(path, word_contents)
          $stderr.puts("#{path}: written #{word_contents.size} bytes")
        end
      end
      
      if (next_tag = index_doc.at_css("a.SEGUENTS"))
        next_index = next_tag.attribute("href").value[/\d+/, 0]
        index_url = IndexUrlTemplate % {index: next_index}
      else
        break
      end 
    end
  end
end

Diccionaris.download_all("output")
