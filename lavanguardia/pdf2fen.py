#!/usr/bin/python2
import sys
import re
import subprocess

# Package modules
import chess

# Generic functions

def debug(line):
    """Output line to standard error."""
    sys.stderr.write(line + "\n")
    sys.stderr.flush()
  
def run(command, inputdata=None, **kwargs):
    """Run command (with optional input) and return retcode/stdout/stderr"""
    default_kwargs = dict(stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    popen = subprocess.Popen(command, **dict(default_kwargs, **kwargs))
    outdata, errdata = popen.communicate(inputdata)
    return popen.returncode, outdata, errdata

def first(it, pred=bool):
    """Return first element in iterator that matches predicate."""
    for x in it:
        if pred(x):
            return x
  
def create_matrix(shape, value=None):
    """Create matrix (lists of lists)."""
    if not shape:
        return value
    return [create_matrix(shape[1:], value) for _ in xrange(shape[0])]

# Specific functions
  
def debug_board(board):
    """Show a chess board."""
    for index, line in enumerate(board):
        debug("%s %s" % ((8 - index), " ".join((c or "-") for c in line)))
    debug(" "*2 + " ".join("abcdefgh")) 

def parse_text(line):
    """Parse HTML text line and return dictionary with attributes and text."""
    match = re.match("""
      <text\s*
        top="(?P<top>\d+)"\s* 
        left="(?P<left>\d+)"\s* 
        width="(?P<width>\d+)"\s* 
        height="(?P<height>\d+)"\s* 
        font="(?P<font>\d+)">\s*
      (?P<text>.*)</text>""", line, re.VERBOSE)
    return match.groupdict()

def create_board(board_lines, ref_line):
    """Create a 8x8 matrix with board parsed from board_lines."""
    spaces = [u' ', u'\uf02c']
    equivalences = {
        # White pieces
        u'\uf045': 'Q', u'\uf04b': 'Q',
        u'\uf046': 'K', u'\uf04c': 'K',  
        u'\uf041': 'P', u'\uf047': 'P',
        u'\uf04a': 'R', u'\uf044': 'R',
        u'\uf048': 'N', u'\uf042': 'N',
        u'\uf043': 'B', u'\uf049': 'B',
        # Black pieces
        u'\uf06a': 'r', u'\uf064': 'r',
        u'\uf067': 'p', u'\uf061': 'p',
        u'\uf06c': 'k', u'\uf066': 'k',
        u'\uf062': 'n', u'\uf068': 'n',
        u'\uf065': 'q', u'\uf06b': 'q',
        u'\uf063': 'b', u'\uf069': 'b',    
    }
    y_offset = 573 - 575
    x_offset = 647 - 625

    ref_info = parse_text(ref_line)
    ref_top, ref_left = map(int, [ref_info["top"], ref_info["left"]])  
    board = create_matrix((8, 8), None)
      
    for y, board_line in enumerate(board_lines):
        info = parse_text(board_line)
        top, left = map(int, [info["top"], info["left"]])
        #y = (top - ref_top - y_offset)/16
        x = int(round((left - ref_left - x_offset)/16.0))
        for xindex, char in enumerate(unicode(info["text"], "utf8")):
            if char not in spaces:
                assert (char in equivalences), "Piece not configured: %s (%s%d)" % \
                    (repr(char), "abcdefgh"[x+xindex], 8-y)
                board[y][x+xindex] = equivalences[char]
    return board
    
def pdf2fen(pdffile):
    """Convert La Vanguardia PDF to FEN notation.""" 
    debug("pdf file: %s" % pdffile)
    retcode, output, err = run(["pdftohtml", "-xml", "-stdout", pdffile])
    assert (retcode == 0), "Error running pdftohtml:\n%s" % err
    lines = [s.replace("JUEGUEN", "JUGUEN") for s in output.splitlines()]
    
    tomove = first(re.search(r'<b>(\w+) (JUEGAN Y|JUGUEN I)', line) 
        for line in lines).group(1).lower()
    assert (tomove in ["blancas", "blanques", "negras", "negres"]), \
      "Error parsing whose turn is: %s" % tomove
    debug("to move: %s" % tomove)
    white_to_move = (tomove in ("blancas", "blanques"))
    
    ref_line = first(line for line in lines if '<text' in line and 
      (' JUEGAN Y' in line or ' JUGUEN I' in line))
    ref_index = first(idx for idx, line in enumerate(lines) if '>8</text>' in line)
    assert ref_index, "Error finding reference line"
    board_lines = lines[ref_index+1:(ref_index+1)+16:2]
    assert (len(board_lines) == 8), "Wrong board lines: %d" % len(board_lines)
    board = create_board(board_lines, ref_line)
    debug_board(board) 
    return chess.get_fen_notation(board, whitetomove=white_to_move, 
        whitecastle="kq", blackcastle="kq")
  
# Main

def main(args):
  pdffile, = args  
  print pdf2fen(pdffile)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
