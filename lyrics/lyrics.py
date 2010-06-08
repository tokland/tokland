#!/usr/bin/python
"""
Download lyrics from LyricWiki. 

Before running, you need to install the ZSI module. To re-create the 
LyricWiki_services module, run:

    $ wsdl2py --complexType --url=http://lyricwiki.org/server.php?wsdl
    
More info: http://lyricwiki.org/LyricWiki:SOAP/Python

Author: 2007 Arnau Sanchez <arnau@ehas.org>
"""
import sys
import os

import LyricWiki_services as lyricwiki

__all__ = ["get_lyrics_for_song"]

def write(obj, s):
    """Write a line to a file-like object"""
    obj.write(s+"\n")
    obj.flush()
    
def error(s):
    """Write a line to standard error"""
    write(sys.stderr, s)
    
def output(s):
    """Write a line to standard output"""
    write(sys.stdout, s)
    
def get_lyrics_for_song(soap_url, artist, songtitle):
    """Get lyrics from a artist/songtitle"""
    soap = lyricwiki.LyricWikiBindingSOAP(soap_url)
    song = lyricwiki.getSongRequest()
    song.Artist = artist
    song.Song = songtitle
    result = soap.getSong(song)
    lyrics = result.Return.Lyrics
    if not lyrics or "not found" in lyrics.splitlines()[0].lower():
        return        
    return result.Return.Lyrics
        
def main(args, soap_url = "http://lyricwiki.org/server.php"):
    import optparse
    usage = """usage: %prog [OPTIONS] ARTIST SONG

    Get lyrics for a song from LyricsWiki"""
    parser = optparse.OptionParser(usage)
    parser.add_option('-u', '--soap-url', dest='soap_url', 
        type='string', default=soap_url, metavar='URL', 
        help='URL to access the SOAP service')
    options, args0 = parser.parse_args()
    if len(args0) != 2:
        parser.print_help()
        return 1
    artist, song = args0
    res = get_lyrics_for_song(options.soap_url, artist, song)
    if not res:
        return 2
    output(res)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
