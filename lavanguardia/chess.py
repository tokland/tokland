#!/usr/bin/python
import operator
import itertools

WHITE_PIECES = "RKBPQN"
BLACK_PIECES = "rkbpqn"

def get_san_rank(rank):
    """Return SAN notation of rank."""
    if not rank:
	      return ""
    nblank = len(list(itertools.takewhile(operator.not_, rank)))
    if nblank:
        return str(nblank) + get_san_rank(rank[nblank:]) 
    else: 
        return rank[0] + get_san_rank(rank[1:])

def get_fen_notation(board, whitetomove=True, whitecastle="kq",
        blackcastle="kq", enpassant=None, halfmove=0, fullmove=1):
    """Return FEN notation of a board."""
    pieces = "/".join(get_san_rank(rank) for rank in board)
    white_to_move_string = ("w" if whitetomove else "b")
    castle = whitecastle.upper() + blackcastle.lower()
    return " ".join([
        pieces, 
        white_to_move_string, 
        castle or "-", 
        enpassant or "-", 
        str(halfmove), 
        str(fullmove),
    ])
