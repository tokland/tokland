#!/usr/bin/python
"""Download the great XKCD cartoon. 

Use the descriptive "alt" text of the image as output filename."""
import BeautifulSoup
import optparse
import urllib2
import sys
import os

def debug(obj):
    """Print a debug info line to stderr"""
    sys.stderr.write("--- " + str(obj)+"\n")
    sys.stderr.flush()

def get_soup(url):
    """Return a BeautifulSoup from plain HTML data"""
    debug("downloading: %s" % url)
    data = urllib2.urlopen(url).read()
    return BeautifulSoup.BeautifulSoup(data)

###

def get_last_num(baseurl):
    """Get the last published cartoon index"""
    debug("getting last cartoon index")
    homesoup = get_soup(baseurl)
    previous_anchors = homesoup.findAll("a", {'accesskey': 'p'})
    index = int(previous_anchors[0]["href"].strip("/")) + 1
    debug("last picture index: %d" % index)
    return index

def download_image(soup):
    """Download cartoon image given its index and HTML soup"""
    image = soup.find(id="contentContainer").img
    title = image["title"].strip().strip(".").replace("/", "-")
    extension = os.path.splitext(image["src"])[1]
    debug("download image: %s" % image["src"])
    data = urllib2.urlopen(image["src"]).read()
    return title, extension, data 

def download_cartoon(baseurl, num):
    """Get the 'num' XKCD cartoon"""
    soup = get_soup(os.path.join(baseurl, str(num)))
    title, image_extension, data = download_image(soup)
    filename = "%03d.%s%s" % (num, title, image_extension)
    open(filename, "w").write(data)
    debug(filename)

def main(args0):
    """Process options and arguments"""
    usage = "usage: download_xkcd.py [options] [start [end]]\n\n  %s" % __doc__
    parser = optparse.OptionParser(usage)
    parser.add_option('-u', '--url', dest='baseurl', metavar="URL",
        default="http://xkcd.com", type="string", help='XKCD main page URL')
    options, args = parser.parse_args(args0)
    if len(args) == 0:
        start, end = 1, get_last_num(options.baseurl)
    elif len(args) == 1:
        start, end = int(args[0]), get_last_num(options.baseurl)
    else: start, end = map(int, args[:2])
       
    debug("download XKCD from %d to %d" % (start, end))    
    for num in xrange(start, end+1):
        download_cartoon(options.baseurl, num)
        
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
