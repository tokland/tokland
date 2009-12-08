#!/usr/bin/python
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this library.  If not, see <http://www.gnu.org/licenses/>.

"""
Simple script to upload videos to Youtube.
"""

import re
import sys
import urllib
import optparse

import gdata.media
import gdata.geo
import gdata.youtube
import gdata.youtube.service
from xml.etree import ElementTree

DEVELOPER_KEY = 'AI39si7iJ5TSVP3U_j4g3GGNZeI6uJl6oPLMxiyMst24zo1FEgnLzcG4iSE0t2pLvi-O03cW918xz9JFaf_Hn-XwRTTK7i1Img'

class Youtube:
    """Interface the Youtube API."""
        
    CATEGORIES_SCHEME = "http://gdata.youtube.com/schemas/2007/categories.cat"
    
    def __init__(self, email, password, source=None, client_id=None):
        """Login and preload available categories."""
        service = gdata.youtube.service.YouTubeService()
        service.email = email
        service.password = password
        service.source = source
        service.developer_key = DEVELOPER_KEY
        service.client_id = client_id
        service.ProgrammaticLogin()
        self.service = service
        self.categories = self.get_categories()
        
    def upload_video(self, path, title, description, category, keywords=None, location=None):
        """Upload a video to youtube along with some metadata."""
        assert self.service, "Youtube service object is not set"
        assert category in self.categories, "Category not found: %s" % category
                 
        media_group = gdata.media.Group(
            title=gdata.media.Title(text=title),
            description=gdata.media.Description(description_type='plain', text=description),
            keywords=gdata.media.Keywords(text=", ".join(keywords or [])),
            category=gdata.media.Category(
                text=category,
                label=self.categories[category],
                scheme=self.CATEGORIES_SCHEME),
            player=None)
        where = gdata.geo.Where()
        if location:
            where.set_location(location)
        video_entry = gdata.youtube.YouTubeVideoEntry(media=media_group, geo=where)
        return self.service.InsertVideoEntry(video_entry, path)

    @classmethod
    def get_categories(cls):
        """Return categories dictionary with pairs (term, label)."""
        xmldata = urllib.urlopen(cls.CATEGORIES_SCHEME).read()
        xml = ElementTree.XML(xmldata)    
        return dict((el.get("term"), el.get("label")) for el in xml)

def main_upload(args):
    """Upload video to Youtube."""
    usage = """Usage: %prog [OPTIONS] EMAIL PASSWORD FILE TITLE DESCRIPTION CATEGORY KEYWORDS

    Upload videos to youtube."""
    parser = optparse.OptionParser(usage)
    parser.add_option('-c', '--get-categories', dest='get_categories',
          action="store_true", default=False, help='Show categories')
    options, args0 = parser.parse_args(args)
    
    if options.get_categories:
        print ", ".join(Youtube.get_categories().keys())
        return 0
    elif len(args0) != 7:
        parser.print_usage()
        return 1
    
    email, password, video_file, title, description, category, skeywords = args0
    yt = Youtube(email, password)
    keywords = filter(bool, re.split('[,;\s]+', skeywords)) 
    entry = yt.upload_video(video_file, title, description, category, keywords)
    url = entry.GetHtmlLink().href.replace("&feature=youtube_gdata", "")
    print url
    
if __name__ == '__main__':
    sys.exit(main_upload(sys.argv[1:]))
