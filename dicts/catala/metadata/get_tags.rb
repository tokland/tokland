require 'uri'
require 'json'
require 'rest-client'
require 'nokogiri'
require 'active_support/core_ext/object'

url = "http://www.diccionari.cat/abrev.jsp?ABRE=A"
baseurl = URI.join(url, "/")

index_doc = Nokogiri::HTML(RestClient.get(url))
urls = [url] + index_doc.css("a.enllas_2").map do |a|
  URI.join(baseurl, a.attribute("href").value).to_s
end

abbrs_pairs = urls.flat_map do |url|
  doc = Nokogiri::HTML(RestClient.get(url))
  table = doc.at_css("td.CentreTextTD > table:last()")
  tds = table.css("td").select { |td| td.attribute("valign").try(:value) == "0" }
  tds.map(&:text).each_slice(2).flat_map do |skey, value|
    skey.split(",").map { |key| [key.strip, value] }
  end
end

path = "abbreviations.json"
File.write(path, JSON.pretty_generate(Hash[abbrs_pairs]))
puts(path)
