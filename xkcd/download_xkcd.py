#!/usr/bin/python
"""Download the great XKCD cartoons. Uses the descriptive "title" 
attribute of the image to write the output filename"""

# Author: <tokland@gmail.com>

import BeautifulSoup
import optparse
import urlparse
import urllib2
import glob
import sys
import os

def debug(obj):
    """Print a debug info line to stderr"""
    sys.stderr.write("--- %s\n" % obj)
    sys.stderr.flush()

def get_soup(url):
    """Return a BeautifulSoup from plain HTML data"""
    debug("downloading: %s" % url.encode("utf-8"))
    data = urllib2.urlopen(url).read()
    return BeautifulSoup.BeautifulSoup(data)

###

def get_last_num(baseurl):
    """Get the last published cartoon index"""
    debug("getting last cartoon index")
    homesoup = get_soup(baseurl)
    previous_anchor = homesoup.find("a", {'accesskey': 'p'})
    index = int(previous_anchor["href"].strip("/")) + 1
    debug("last picture index: %d" % index)
    return index

def download_image(soup):
    """Download cartoon image given its index and HTML soup"""
    image = soup.find("div", {"id": "middleContent", "class": "dialog"}).img
    assert image, "could not find image tag from html soup"
    title = image["title"].strip().strip(".").replace("/", "-")
    extension = os.path.splitext(image["src"])[1]
    debug("download image: %s" % image["src"])
    data = urllib2.urlopen(image["src"]).read()
    return title, extension, data 

def download_cartoon(baseurl, num, force=False, index_format="%03d."):
    """Get the ntk XKCD cartoon (404th is missing, you know why)"""
    header = index_format % num
    if not force:
        existing = glob.glob(header+"*")
        if existing:
            debug("skipping: %s" % existing[0])
            return
    try: 
        soup = get_soup(urlparse.urljoin(baseurl, str(num)))
    except urllib2.HTTPError:
        debug("cartoon not found: %s" % num)
        return
    title, image_extension, data = download_image(soup)
    filename = header + title + image_extension
    open(filename, "w").write(data)
    debug(filename.encode("utf-8"))

def main(args0):
    """Process options and arguments"""
    usage = "usage: download_xkcd.py [options] [start [end]]\n\n  %s" % __doc__
    parser = optparse.OptionParser(usage)
    parser.add_option('-u', '--url', dest='baseurl', metavar="URL",
        default="http://xkcd.com", type="string", help='XKCD main page URL')
    parser.add_option('-f', '--force', dest='force', default=False,
        action='store_true', help="Overwrite existing images")
    options, args = parser.parse_args(args0)
    if len(args) == 0:
        start, end = 1, get_last_num(options.baseurl)
    elif len(args) == 1:
        start, end = int(args[0]), get_last_num(options.baseurl)
    else: start, end = map(int, args[:2])
       
    debug("downloading XKCD cartoons from %d to %d" % (start, end))
    if options.force:
        debug("force enabled")    
    for num in xrange(start, end+1):
        download_cartoon(options.baseurl, num, force=options.force)
        
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
