#!/usr/bin/python
"""
Brute-force Sudoku solver written in functional-programming style.

- Dictionary version 
- Starts from the more constrained squares (faster)

Author: Arnau Sanchez <tokland@gmail.com>
License: GNU GPL v3.0
Webpage: http://code.google.com/p/wiki/Projects 

= How it works:
    
The algorithm starts by finding an empty square on the board and getting
the list of valid digits for this square. Then it tries these digits calling 
the solver function.

If at some point no valid digit for a square if found (meaning a previously 
tested digit was wrong) the algorithm goes back. Eventually, all squares 
will be filled and the board containing the solution will travel all the stack 
up to the caller.
  
= How to run the script
       
Create a text-file with a 9x9 grid, using spaces the way you like. For example:
  
    6 - -  - - -  - 8 3
    - - 7  1 - -  - - 4
    - - 9  - - 2  7 - -

    - - -  5 - 9  - - -
    1 - -  3 4 8  - - 9
    - - -  7 - 1  - - -

    - - 5  9 - -  3 - -
    3 - -  - - 6  1 - -
    7 6 -  - - -  - - 8
  
And then run the script with the text filename as argument:

$ python sudoku2.py mysoduku.txt
"""
import re
import sys

def get_alternatives_for_square(board, pos):
    """Return sequence of possible digits for square pos (nrow, ncolumn)."""
    def _box(idx):
        """Return indexes to cover a box (3x3 sub-matrix of a board)."""
        start = (idx // 3) * 3 
        return range(start, start + 3)
    nrow, ncolumn = pos
    nums_in_box = [board.get((r, c), None) for r in _box(nrow) for c in _box(ncolumn)]
    nums_in_row = [board.get((nrow, c), None) for c in range(9)]
    nums_in_column = [board.get((r, ncolumn), None) for r in range(9)]
    nums = nums_in_box + nums_in_row + nums_in_column
    return sorted(set(range(1, 9+1)) - set(nums)) 

ranges = [(x, y) for x in range(9) for y in range(9)]

def get_more_constrained_square(board):
    """Get square in board with less possible digits."""
    alternatives = ((len(get_alternatives_for_square(board, pos)), pos) 
                    for pos in ranges if pos not in board)
    return min(alternatives)[1]
 
def solve(board):
    """Return a solved Sudoku board (None if no solution was found)."""
    if len(board) == 9 * 9:
        return board
    pos = get_more_constrained_square(board)
    for test_digit in get_alternatives_for_square(board, pos):
        test_board = dict(board, **{pos: test_digit})
        solved_board = solve(test_board)
        if solved_board:
            return solved_board

def print_board(board, stream=sys.stdout):
    """Print a Sudoku board to stream."""
    lines = [[str(board.get((r, c), "-")) for c in range(9)] for r in range(9)]
    stream.writelines(" ".join(line)+"\n" for line in lines)
    
def parse_board(data):
    """Parse a text board stripping spaces and setting."""
    return dict((divmod(idx, 9), int(c)) for (idx, c) in 
                enumerate(re.sub("\s+", "", data)) if c in "1234546789")

def main(args):
    """Solve a Sudoku board read from a text file."""
    path, = args
    board = parse_board(open(path).read())
    print_board(board)
    print
    print_board(solve(board))
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
