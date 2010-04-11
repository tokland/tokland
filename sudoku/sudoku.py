#!/usr/bin/python
"""
Simple Sudoku solver (not optimized) that uses functional-programming style.

The board must be a 9x9 grid with digits (use any other char for empty squares). 
You can format the board with spaces the way you like (they will be all removed).

Example:
  
  6-- --- -83
  --7 1-- --4
  --9 --2 7--

  --- 5-9 ---
  1-- 348 --9
  --- 7-1 ---

  --5 9-- 3--
  3-- --6 1--
  76- --- --8
"""
import re
import sys

def copy_board(board, new_values):
    """Return a copy of board setting values in new_values dictionary."""
    return [[new_values.get((r, c), board[r][c]) for c in range(9)] for r in range(9)] 
            
def get_alternatives_for_square(board, nrow, ncolumn):
    """Return sequence of valid digits for (nrow, ncolumn) square in board."""
    box_row, box_column = 3 * (nrow / 3), 3 * (ncolumn / 3)
    nums_in_box = [board[r][c] for r in range(box_row, box_row+3) 
                               for c in range(box_column, box_column+3)]
    nums_in_row = [board[nrow][c] for c in range(9)]
    nums_in_column = [board[r][ncolumn] for r in range(9)]
    groups = [filter(bool, x) for x in [nums_in_box, nums_in_row, nums_in_column]]
    return sorted(set(range(1, 10)) - set(sum(groups, []))) 
     
def solve(board):
    """Return a solved Sudoku board (return None if if no valid solution)."""
    for nrow in range(9):
        for ncolumn in range(9):
            if board[nrow][ncolumn]:
                # the square has a digit, go to the next one
                continue
            for test_digit in get_alternatives_for_square(board, nrow, ncolumn):
                new_board = copy_board(board, {(nrow, ncolumn): test_digit})
                solved_board = solve(new_board)
                if solved_board:
                    # return the solved board all the way up to break recursion
                    return solved_board
            return
    # all squares are filled, so this must be the solution. 
    return board 

def lines2board(lines):
    """Return a board using 0 for empty squares and removing all spaces."""
    return [[(int(c) if c in "123456789" else 0) for c in re.sub("\s+", "", line)] 
            for line in lines if line.strip()]

def main(args):
    """Solve a Sudoku board read from a file (first arguments of args)."""
    from pprint import pprint
    path, = args
    board = lines2board(open(path))
    pprint(board)
    print "---"
    pprint(solve(board))
    
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
