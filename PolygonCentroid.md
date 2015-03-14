# Introduction #

The algorithm:

http://en.wikipedia.org/wiki/Centroid#Centroid_of_polygon

Ruby code:

http://code.google.com/p/tokland/source/browse/trunk/centroid

# Example: find the center of Catalonia #

KML used: http://tokland.googlecode.com/files/catalunya.kml

(see it in Google maps: http://g.co/maps/qfa9e)

```
$ wget http://tokland.googlecode.com/svn/trunk/centroid/center.rb
$ ruby center.rb
Long: 1.5286424793097 Lat: 41.7982954227561
http://maps.google.es/maps?cx=w&q=1.5286424793097E+41.7982954227561N&z=13
```

Center: http://maps.google.es/maps?cx=w&q=1.5286424793097E+41.7982954227561N&z=13