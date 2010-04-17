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

def get_alternatives_for_square(board, nrow, ncolumn):
    """Return sequence of valid digits for square (nrow, ncolumn) in board."""
    def _box(idx):
        """Return indexes to cover a box (3x3 sub-matrix of a board)."""
        start = (idx // 3) * 3 
        return range(start, start + 3)
    nums_in_box = [board.get((r, c), None) for r in _box(nrow) for c in _box(ncolumn)]
    nums_in_row = [board.get((nrow, c), None) for c in range(9)]
    nums_in_column = [board.get((r, ncolumn), None) for r in range(9)]
    nums = nums_in_box + nums_in_row + nums_in_column
    return sorted(set(range(1, 9+1)) - set(nums)) 

ranges = [(x, y) for x in range(9) for y in range(9)]
        
def get_more_constrained_square(board):
    """Get the square in board with more constrains (with less alternatives)."""
    alternatives = ((len(get_alternatives_for_square(board, r, c)), (r, c)) 
        for (r, c) in ranges if (r, c) not in board)
    return min(alternatives)[1]
 
def solve(board):
    """Return a solved Sudoku board (None if no solution was found)."""
    if len(board) == 9 * 9:
        return board
    nrow, ncolumn = get_more_constrained_square(board)
    for test_digit in get_alternatives_for_square(board, nrow, ncolumn):
        test_board = dict(board, **{(nrow, ncolumn): test_digit})
        solved_board = solve(test_board)
        if solved_board:
            return solved_board

def print_board(board, stream=sys.stdout):
    """Print a Sudoku board to stream."""
    lines = [[str(board.get((r, c), "-")) for c in range(9)] for r in range(9)]
    stream.writelines(" ".join(line)+"\n" for line in lines)
    
def lines2board(lines):
    """Parse a text board stripping spaces and setting 0's for empty squares."""
    def _get_squares(lines):
        for nrow, line in enumerate(line for line in lines if line.strip()):
            for ncolumn, c in enumerate(re.sub("\s+", "", line)):
                if c in "1234546789":
                    yield ((nrow, ncolumn), int(c))                    
    return dict(_get_squares(lines))

def main(args):
    """Solve a Sudoku board read from a text file."""
    path, = args
    board = lines2board(open(path))
    print list(sorted(board.items()))
    print_board(board)
    print "-" * (2*9-1)
    print_board(solve(board))
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
