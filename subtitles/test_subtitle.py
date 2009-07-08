#!/usr/bin/python
from StringIO import StringIO
import unittest
import tempfile

import subtitle

SUBTITLE = """
1
00:00:20,000 --> 00:00:24,400
In connection with a dramatic increase
in crime in certain neighbourhoods,

2
00:00:24,600 --> 00:00:27,800
the government is implementing a new policy...
""".lstrip()

SUBTITLE_SCALED = """
1
00:00:19,180 --> 00:00:23,400
In connection with a dramatic increase
in crime in certain neighbourhoods,

2
00:00:23,592 --> 00:00:26,661
the government is implementing a new policy...
""".lstrip()

PARSED = {
    1: {
        "timing": [20000, 24400],
        "text": ["In connection with a dramatic increase",
                 "in crime in certain neighbourhoods,"],
    },            
    2: {
        "timing": [24600, 27800],
        "text": ["the government is implementing a new policy..."],
    }            
}


class SubtitleModuleTest(unittest.TestCase):                       
    def test_parse_timing(self):
        self.assertEqual(2*60*60*1000+10*60*1000+24*1000+400, 
            subtitle.parse_timing("02:10:24,400"))

    def test_unparse_timing(self):
        self.assertEqual("02:10:24,023", 
            subtitle.unparse_timing(2*60*60*1000+10*60*1000+24*1000+23))

                    
class SubtitleTest(unittest.TestCase):
    def setUp(self):
        self.sub = subtitle.Subtitle(StringIO(SUBTITLE))
                                            
    def test_init_with_stream(self):
        sub = subtitle.Subtitle(StringIO(SUBTITLE))
        self.assertEqual(SUBTITLE, sub.data)
        
    def test_init_with_file(self):
        tfile = tempfile.NamedTemporaryFile()
        tfile.write(SUBTITLE)
        tfile.flush()
        sub = subtitle.Subtitle(tfile.name)
        self.assertEqual(SUBTITLE, sub.data)

    def test_parsed(self):
        self.assertEqual(PARSED, self.sub.parsed)

    def test_scale(self):
        self.sub.scale(23.976 / 25.0)
        self.assertEqual(SUBTITLE_SCALED, self.sub.data)


if __name__ == '__main__':
    unittest.main()
