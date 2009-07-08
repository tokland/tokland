#!/usr/bin/python
"""Process SRT subtitle files.""" 
import itertools
import sys
import re

TIMING_FIELDS = (60*60*1000, 60*1000, 1*1000, 1)

def parse_timing(s):
    """Return mseconds of string s (format: hours:minutes:seconds,msecs)"""
    fields = map(int, re.match("(\d+):(\d+):(\d+),(\d+)", s).groups())
    return sum(map(lambda x, y: x*y, fields, TIMING_FIELDS))

def unparse_timing(msecs):
    """Return string from mseconds (format: hours:minutes:seconds,msecs)"""
    fields = []
    for factor in TIMING_FIELDS:
        div, mod = divmod(msecs, factor)
        msecs = mod
        fields.append(div)
    return "%02d:%02d:%02d,%03d" % tuple(fields)    

def parse_subtitle(data):
    """Yield subtitles entries.
    
        1
        00:00:20,000 --> 00:00:24,400
        In connection with a dramatic increase
        in crime in certain neighbourhoods,
         
    yields:
    
        (1, 
            {"timing": [20000, 24400],
             "text": ["In connection with a dramatic increase",
                      "in crime in certain neighbourhoods,"]}
        )
    """
    data2 = data.strip().splitlines()
    for match, group in itertools.groupby(data2, lambda s: bool(s.strip())):
        if match:
            entry = list(group)
            number, timing, text = entry[0], entry[1], entry[2:]
            start, end = timing.split(" --> ")
            startms = parse_timing(start)
            endms = parse_timing(end)                    
            yield int(number), dict(timing=[startms, endms], text=text)

def unparse_subtitle(dsubtitles):
    """Unparse subtitle (see parse_subtitles)."""
    def _generator(items):
        for num, entry in sorted(items):        
            start, end = entry["timing"]
            timing = unparse_timing(start) + " --> " + unparse_timing(end) 
            yield "\n".join([str(num), timing, "\n".join(entry["text"])]) + "\n"
    return "\n".join(_generator(dsubtitles.iteritems()))
                
class Subtitle:    
    """Process a subtitle.
    
    >>> import subtitle
    >>> sub = subtitle.Subtitle(path)
    >>> sub.factor(23.976 / 25.0)
    >>> sub.parsed
    ...
    >>> sub.data
    """
    def __init__(self, infile):
        """Load subtitle (file path or file object)."""
        if hasattr(infile, 'read'):
            self.data = infile.read()
        else:
            self.data = open(infile).read()
        self.parsed = dict(parse_subtitle(self.data))

    def scale(self, factor):
        for num, entry in self.parsed.iteritems():
            start, end = entry["timing"]
            entry["timing"] = [start * factor, end * factor]
        self.data = unparse_subtitle(self.parsed)        


def main(args0):
    """Process a subtitle and output to standard error.

    $ python subtitle.py -s 23.976/25.0 subtitle.srt
    """ 
    usage = """usage: subtitle [options] FILE

    Process a subtitle.""" 
    import optparse
    parser = optparse.OptionParser(usage)
    parser.add_option('-s', '--scale', dest='scale', default=None, 
        metavar="FLOAT1/FLOAT2", type="string", 
        help='Apply timing factor scale (N/M)')
    options, args = parser.parse_args(args0)
    if not args:
        parser.print_help()
        return 1
    path, = args
    sub = Subtitle(sys.stdin if (path == '-') else path)
    if options.scale:
        a, b = map(float, options.scale.split("/"))
        sub.scale(a / b)
    sys.stdout.write(sub.data)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
