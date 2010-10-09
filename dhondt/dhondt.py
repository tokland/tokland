#!/usr/bin/python
"""
Calculate seats distribution according to the D'Hondt method.

Author: Arnau Sanchez <tokland@gmail.com>
License: GPLv3
"""
import operator

def merge(d, d2):
    """Merge dictionary d2 into d."""
    return dict(d, **d2)
  
def dhondt(polling, total_seats, min_percent=5.0):
    """
    Calculate seats distribution according to the D'Hondt method.
    
    Given a diccionary of (party, votes) pairs and the total seats
    to distribute, return a dictionary of (party, seats) pairs.
    
    >>> dvotes = {"a": 100, "b": 90, "c": 20}  
    >>> sorted(dhondt(dvotes, 10, 5.0).items())
    [('a', 5), ('b', 4), ('c', 1)]
    """
    def _process(dvotes, current_dvotes, results, pending_seats):
        if not pending_seats:
            return results
        party, nvotes = max(current_dvotes.items(), key=operator.itemgetter(1))
        seats = results[party] + 1
        new_current_dvotes = merge(current_dvotes, {party: dvotes[party] / (seats+1)})
        new_results = merge(results, {party: seats})
        return _process(dvotes, new_current_dvotes, new_results, pending_seats-1)
      
    total_votes = sum(polling.values())
    dvotes = dict((party, votes) for (party, votes) in polling.items() 
        if float(100*votes) / total_votes >= min_percent)
    return _process(dvotes, dvotes, dict.fromkeys(dvotes, 0), total_seats)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
