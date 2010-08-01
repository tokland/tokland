#!/usr/bin/python
"""Download PDF page that contains the daily chess problem of La Vanguardia"""
from itertools import ifilter, takewhile, starmap, repeat
import BeautifulSoup
import cookielib
import urllib2
import time
import sys
import re
import os

def debug(obj, linefeed=True):
    """Print a debug info line to standard error channel"""
    strobj = str(obj) + ("\n" if linefeed else "")
    sys.stderr.write(strobj)
    sys.stderr.flush()
        
def first(iterator, pred=bool):
    """Return first item in iterator that matches the predicate"""
    return ifilter(pred, iterator).next()
                
def get_soup(data):
    """Return a BeautifulSoup from plain HTML data"""
    return BeautifulSoup.BeautifulSoup(data)
    
def get_cookies_opener(filename):
    """Open a cookies file and return a urllib2 opener object"""
    cookies = cookielib.MozillaCookieJar()
    cookies.load(filename)
    return urllib2.build_opener(urllib2.HTTPCookieProcessor(cookies))

def simple_progression(data):
    """Write a dot (no carry return) on progression. Output a CR on end"""
    debug(*([".", False] if data else [""]))
    return bool(data)

def progress_function(callback, func, *args):
    """Progress function (using itertools).
    
    progress_callback is called with the return value 
    of func(*args). The callback should return False to stop."""
    return takewhile(callback, starmap(func, repeat(args)))
   
def download(url, opener, buffersize=256):
    """Download a URL, optionally using an opener"""
    debug("download: %s " % url, False)
    func = opener.open(url).read
    return "".join(progress_function(simple_progression, func, buffersize))

###
        
def get_vanguardia_index(date, opener):
    """Return the main index of the newspaper for a given date (YYYYMMDD)"""
    url = "http://www.lavanguardia.es/free/epaper/%s/index.html" % date
    return download(url, opener)
    
def download_chess(date, cookiesfile):
    """Download chess page and return PDF filename and its contents"""
    opener = get_cookies_opener(cookiesfile)    
    index = get_soup(get_vanguardia_index(date, opener))
    condition = lambda li: "Pasatiempos" in li.find("a").contents[0] 
    pasatiempos_url = first(index.findAll("li"), condition).a["href"]
    #pasatiempos = get_soup(download(pasatiempos_url, opener))
    #ajedrez_url = first(pasatiempos.findAll("a", {"class": "CalDesc"}))["href"]
    ajedrez_url = pasatiempos_url
    ajedrez = download(ajedrez_url, opener)
    pdf_url = re.search("strPdf\s*=\s*'(http://.*?)'", ajedrez).group(1)
    filename = os.path.basename(pdf_url)
    contents = download(pdf_url, opener)
    return filename, contents

def process_date(date):
    """From string containing DD, MMDD or YYYYMMDD dates, obtain YYYYMMDD. 
    Use current date for missing fields""" 
    fields_length = [8, 4, 2, 0]
    datefields = ["%Y", "%m", "%d"]
    assert any(len(date) == length for length in fields_length), \
        "Date string should be of format DD|MMDD|YYYYMMDD: %s" % date
    assert re.match("^\d*$", date), "Date must be a numeric string: %s" % date
    index = fields_length.index(len(date))
    padding = "".join(datefields[:index])        
    return time.strftime(padding + date)

### Main

def main(args):
    """Get arguments (cookie and optional date) and write PDF file 
    containing the chess problem"""
    cookiesfile, datearg = args[0], args[1:]
    date = process_date(datearg[0] if datearg else "")
    filename, contents = download_chess(date, cookiesfile)    
    open(filename, "w").write(contents)
    print filename
   
if __name__ == "__main__":
    main(sys.argv[1:])
