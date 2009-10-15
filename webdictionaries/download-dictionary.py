#!/usr/bin/python
"""
Download web dictionaries that show adjacent words.

Dictionaries known to work: wordreference and freedictionary
"""
import optparse
import subprocess
import htmllib
import urllib2
import urllib
import sys
import os

# Third-party modules
import BeautifulSoup

dictionaries = {
    "wordreference-en-es": {
        "startword": "-shaped",
        "url": "http://www.wordreference.com/es/translation.asp?tranword=%s",
        "links": ("div", {"class": "closeWords"}),
    },
    "wordreference-fr-es": {
        "startword": "a",
        "url": "http://www.wordreference.com/fres/%s",
        "links": ("div", {"class": "closeWords"}),
    },
    "wordreference-es-en": {
        "startword": "a",
        "url": "http://www.wordreference.com/es/en/translation.asp?spen=%s",
        "links": ("div", {"class": "closeWords"}),
    },        
    "wordreference-es": {
        "startword": "a",
        "url": "http://www.wordreference.com/definicion/%s",
        "links": ("div", {"class": "closeWords"}),
    },    
    "wordreference-thefreedictionary": {
        "startword": "a-",
        "url": "http://www.thefreedictionary.com/%s",
        "links": ("div", {"id": "toggle_td_11"}),
    },
    "thefreedictionary-idioms": {
        "startword": "'em",
        "url": "http://idioms.thefreedictionary.com/%s",
        "links": ("div", {"id": "toggle_td_11"}),
    },
}            

def debug(obj, linefeed=True):
    """Print a debug info line to standard error channel"""
    strobj = str(obj) + ("\n" if linefeed else "")
    sys.stderr.write(strobj)
    sys.stderr.flush()

def unescape_entities(html_string):
    """Removes HTML or XML character references and entities 
    from a html string (see http://wiki.python.org/moin/EscapingHtml)"""
    parser = htmllib.HTMLParser(None)
    parser.save_bgn()
    parser.feed(html_string.encode("iso8859-1"))
    return parser.save_end()
                    
def get_soup(data):
    """Return a BeautifulSoup object from HTML data"""
    soup = BeautifulSoup.BeautifulSoup(data)
    return soup
       
def download(url):
    """Return contents for a given URL"""
    debug("download: %s " % url)    
    user_agent = 'Mozilla/4.0'
    headers = {'User-Agent': user_agent}
    request = urllib2.Request(url, headers=headers)
    data = urllib2.urlopen(request).read()
    return data

###

def get_word_url(dictionary, word):
    """Get the URL for a given word"""    
    encoded_word = urllib.quote(word)
    url_template = dictionary["url"]
    url = url_template % encoded_word
    return url    

def get_path_for_word(word, outputdir):
    """Return local file path for a given word"""
    filename = word.replace("/", "-") + ".html"
    path = os.path.join(outputdir, filename)
    return path
  
def download_word(dictionary, word, outputdir):
    """Download HTML data for a word, save it and return HTML contents"""
    debug("word: %s" % word)
    filename = get_path_for_word(word, outputdir)
    if os.path.exists(filename):
        return open(filename).read()
    url = get_word_url(dictionary, word)
    data = download(url)
    filename = get_path_for_word(word, outputdir)
    open(filename, "w").write(data)
    return data        

def process_word(word0):
    word = unescape_entities(unicode(word0))
    return unicode(word, "iso8859-15").encode("utf-8")

def save_words(dictionary, word, outputdir):
    """Save all close words"""
    soup = get_soup(download_word(dictionary, word, outputdir))
    tag, conditions = dictionary["links"]
    links = soup.find(tag, conditions).findAll("a")    
    for link in links:
        word = process_word(link.contents[0])
        download_word(dictionary, word, outputdir)
    lastword = process_word(links[-1].contents[0])        
    return lastword

def download_dictionary(dictionary, startword, outputdir):    
    debug("output directory: %s" % os.path.abspath(outputdir))
    word = startword
    while word:
        debug("download page: %s" % word)
        next_word = save_words(dictionary, word, outputdir)
        if word == next_word:
            break
        word = next_word

def _main(args):
    """Main function"""    
    usage = """%%prog [OPTIONS] DICTIONARY OUTPUT_DIRECTORY
    
    Generic webdictionaries downloader.
    
    Available dictionaries: %s""" % ", ".join(sorted(dictionaries.keys()))
    parser = optparse.OptionParser(usage)
    parser.add_option('-s', '--start-word', dest='start_word',
        default=None, metavar="WORD", type="string", help='Force starting word')
    options, args0 = parser.parse_args(args)                
    if len(args) != 2:
        parser.print_help()
        return 1
    dictionaryname, outputdir = args    
    if dictionaryname not in dictionaries:
        parser.print_help()
        debug("supported dictionaries: %s" % ", ".join(dictionaries.keys()))
        return 2
    dictionary = dictionaries[dictionaryname]
    startword = options.start_word or dictionary["startword"]         
    download_dictionary(dictionary, startword, outputdir)
    
if __name__ == '__main__':
    sys.exit(_main(sys.argv[1:]))
