#!/usr/bin/python
"""
Detect and colorize regular expressions in files or standard input.
"""
import sys
import re

ANSI_COLOR_TABLE = {	
    "grey": 30,
    "red": 31, 
    "green": 32, 
    "yellow": 33, 
    "blue": 34, 
    "magenta": 35, 
    "cyan": 36, 
    "white": 37,
}

def ansi_colorize(string, regexp, fg_color):
    """Colorize all matches of regexp found in string with the ANSI code 
    defined by a color string (see ANS_COLOR_TABLE)"""
    code = ANSI_COLOR_TABLE[fg_color]
    ansi_match = "\033[1;%dm%%s\033[0m" % code
    def _replace(match):
        """Surroung match with ANSI color code""" 
        return ansi_match % match.group(1)
    return re.sub('(%s)' % regexp, _replace, string)

def _main(args):
    """Main function for colorize."""
    import optparse
    usage = """usage: colorize [options] REGEXP [FILE]

    Colorize matched regular expression in file or standard input
    """ 
    parser = optparse.OptionParser(usage)
    parser.add_option('-c', '--color', dest='color', default="red", 
        metavar="STRING", type="string", 
        help='Highlight color (%s)' % ", ".join(ANSI_COLOR_TABLE.keys()))
    options, arguments = parser.parse_args(args)
    if not arguments:
        parser.print_help()
        return 2
    elif options.color not in ANSI_COLOR_TABLE:
        parser.print_help()
        sys.stderr.write("\nColor invalid: %s\n" % options.color)        
        return 3
    regexp, paths = arguments[0], arguments[1:]
    streams = (map(open, paths) if paths else [sys.stdin])    
    for stream in streams: 
        for line in stream:
            sys.stdout.write(ansi_colorize(line, regexp, options.color))


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
