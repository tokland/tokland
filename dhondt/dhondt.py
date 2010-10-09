#!/usr/bin/python
"""
Calculate seats distribution according to the D'Hondt method.

Author: Arnau Sanchez <tokland@gmail.com>
Site: http://code.google.com/p/tokland
"""
import operator
from itertools import chain

def merge(*dicts):
    """Merge dictionary d2 into d."""
    return dict(chain.from_iterable(d.iteritems() for d in dicts))

def dhondt(polling, total_seats, min_percentage=5.0):
    """
    Calculate seats distribution according to the D'Hondt method.

    Given a diccionary of (party, votes) pairs and the total seats
    to distribute, return a dictionary of (party, seats) pairs.

    >>> dvotes = {"a": 100, "b": 90, "c": 20, "d": 3}
    >>> sorted(dhondt(dvotes, 10, 5.0).items())
    [('a', 5), ('b', 4), ('c', 1)]
    """
    def _process(dvotes, dvotes_cur, pending_seats, results):
        """Return results for dvotes"""
        if not pending_seats:
            return results
        party, _ = max(dvotes_cur.items(), key=operator.itemgetter(1))
        seats = results[party]+1
        new_dvotes_cur = merge(dvotes_cur, {party: dvotes[party]/(seats+1)})
        new_results = merge(results, {party: seats})
        return _process(dvotes, new_dvotes_cur, pending_seats-1, new_results)
      
    total_votes = sum(polling.values())
    dvotes = dict((party, votes) for (party, votes) in polling.items() 
                  if float(100*votes) / total_votes >= min_percentage)
    return _process(dvotes, dvotes, total_seats, dict.fromkeys(dvotes, 0))

if __name__ == "__main__":
    import doctest
    doctest.testmod()
