#!/usr/bin/python
"""
Brute-force Sudoku solver written in functional-programming style.

Author: Arnau Sanchez <tokland@gmail.com>
License: GNU GPL v3.0
Webpage: http://code.google.com/p/wiki/Projects 

= How it works:
    
The algorithm starts by finding the first empty square on the board and getting
the list of valid digits for this square. Then it loops for every possible 
value calling recursively to the solver function. 

If at some point no valid digit for a square if found (meaning a previously 
tested digit was wrong) the algorithm goes back. Eventually, all squares 
will be filled and the board containing the solution will travel all the stack 
up to the caller.
  
= How to run the script
       
Create a text-file with a 9x9 grid, using spaces the way you prefer. Example:
  
    6-- --- -83
    --7 1-- --4
    --9 --2 7--

    --- 5-9 ---
    1-- 348 --9
    --- 7-1 ---

    --5 9-- 3--
    3-- --6 1--
    76- --- --8
  
And then run the script with the text file as argument:

$ python sudoku.py mysoduku.txt
"""
import re
import sys

def first(it, default=None):
    """Return first element in iterator (None if exhausted)."""
    return next(it, default)

def copy_board(board, sets):
    """Return a copy of board setting new squares from 'values' dictionary."""
    return [[sets.get((r, c), board[r][c]) for c in range(9)] for r in range(9)]
            
def get_alternatives_for_square(board, nrow, ncolumn):
    """Return sequence of valid digits for square (nrow, ncolumn) in board."""
    def _box(idx, size=3):
        """Return indexes to cover a box (3x3 sub-matrix of a board)."""
        start = (idx // size) * size
        return range(start, start + size)
    nums_in_box = [board[r][c] for r in _box(nrow) for c in _box(ncolumn)]
    nums_in_row = [board[nrow][c] for c in range(9)]
    nums_in_column = [board[r][ncolumn] for r in range(9)]
    groups = [nums_in_box, nums_in_row, nums_in_column]
    return sorted(set(range(1, 9+1)) - reduce(set.union, map(set, groups))) 
     
def solve(board):
    """Return a solved Sudoku board (None if no solution was found)."""
    pos = first((r, c) for r in range(9) for c in range(9) if not board[r][c])
    if not pos:
        # all squares are filled, so this board is the solution
        return board
    nrow, ncolumn = pos
    for test_digit in get_alternatives_for_square(board, nrow, ncolumn):
        test_board = copy_board(board, {(nrow, ncolumn): test_digit})
        solved_board = solve(test_board)
        if solved_board:              
            return solved_board

def lines2board(lines):
    """Parse a text board setting 0's for empty squares."""
    spaces = re.compile("\s+")
    return [[(int(c) if c in "123456789" else 0) for c in spaces.sub("", line)]
            for line in lines if line.strip()]

def main(args):
    """Solve a Sudoku board read from a text file."""
    from pprint import pprint
    path, = args
    board = lines2board(open(path))
    pprint(board)
    pprint(solve(board))
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
