#!/usr/bin/ruby
require 'rubygems'
require 'nokogiri'

module Geometry
  # Return centroid point (cx, cy) from polygon coordinates [(x, y)]
  #  
  # Algorithm: http://en.wikipedia.org/wiki/Centroid#Centroid_of_polygon
  def self.polygon_centroid(coordinates)
    consecutive_pairs = (coordinates + [coordinates.first]).each_cons(2)
    area = (1.0/2) * consecutive_pairs.map do |(x0, y0), (x1, y1)|
      (x0*y1) - (x1*y0)
    end.inject(:+)

    consecutive_pairs.map do |(x0, y0), (x1, y1)|
      cross = (x0*y1 - x1*y0)
      [(x0+x1) * cross, (y0+y1) * cross]
    end.transpose.map { |cs| cs.inject(:+) / (6*area) }
  end
end

module Geography
  def self.geographical_center_from_kml(kml_path, placemark_name)
    doc = Nokogiri::XML(open(kml_path))
    string_coordinates = doc.at_css("Placemark > name:contains('%s')" % placemark_name).
      parent.css("coordinates").map(&:text).max_by(&:size)
    coordinates = string_coordinates.split.map { |pair| pair.split(",").map(&:to_f) }
    Geometry::polygon_centroid(coordinates)
  end
end

if __FILE__ == $0
  cx, cy = Geography::geographical_center_from_kml("spain-communities.kml", "Catalunya")
  $stdout.puts "Long: #{cx} Lat: #{cy}"
  $stdout.puts "http://maps.google.es/maps?cx=w&q=#{cx}E+#{cy}N&z=13"  
end
