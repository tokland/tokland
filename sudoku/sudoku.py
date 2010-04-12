#!/usr/bin/python
"""
Simple brute-force Sudoku solver. 

- Functional-programming style.
- Recursive backtracking.
- No heuristics, no optimization at all.
 
The board must be a 9x9 grid (use any non-digit char to denote empty squares).
You can format the board with spaces the way you like (they will be removed).
Example:
    
(mysudoku.txt)
  
  6-- --- -83
  --7 1-- --4
  --9 --2 7--

  --- 5-9 ---
  1-- 348 --9
  --- 7-1 ---

  --5 9-- 3--
  3-- --6 1--
  76- --- --8
  
$ python sudoku.py mysoduku.txt
"""
import re
import sys

def copy_board(board, sets):
    """Return a copy of board setting new squares from values dictionary."""
    return [[sets.get((r, c), board[r][c]) for c in range(9)] for r in range(9)]
            
def get_alternatives_for_square(board, nrow, ncolumn):
    """Return sequence of valid digits for square (nrow, ncolumn) in board."""
    def _box(pos, size=3):
        """Return indexes for a box (sub-matrix of board)."""
        start = (pos // size) * size
        return range(start, start + size)
    nums_in_box = [board[r][c] for r in _box(nrow) for c in _box(ncolumn)]
    nums_in_row = [board[nrow][c] for c in range(9)]
    nums_in_column = [board[r][ncolumn] for r in range(9)]
    groups = [nums_in_box, nums_in_row, nums_in_column]
    return sorted(set(range(1, 10)) - reduce(set.union, map(set, groups))) 
     
def solve(board):
    """Return a solved Sudoku board (None if it has no solution)."""
    for nrow, ncolumn in ((r, c) for r in range(9) for c in range(9)):
        if board[nrow][ncolumn]:
            # digit set, move to the next square
            continue 
        for test_digit in get_alternatives_for_square(board, nrow, ncolumn):
            test_board = copy_board(board, {(nrow, ncolumn): test_digit})
            solved_board = solve(test_board)
            if solved_board:              
                # return the solved board all the way up to break recursion
                return solved_board
        # no solution was found for the square, so let's go back
        return
    # all squares are filled so this must be the solution. 
    return board 

def lines2board(lines):
    """Parse a text board setting 0's for empty squares."""
    spaces = re.compile("\s+")
    return [[(int(c) if c in "123456789" else 0) for c in spaces.sub("", line)]
            for line in lines if line.strip()]

def main(args):
    """Solve a Sudoku board read from a file."""
    from pprint import pprint
    path, = args
    board = lines2board(open(path))
    pprint(board)
    pprint(solve(board))
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
