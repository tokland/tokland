#!/usr/bin/python
"""
Based on a simple math game: given a bunch of numbers, and using the basic 
operations (+, -, /, *)  between them, find (or be as close as possible to) 
another given number.
"""

# Author: arnau sanchez <tokland@gmail.com>

import sys
import operator
import optparse

# Best current approximation (global variable)
best = None

def get_strnum(num):
    """Get pair of (integer_value, string_representation) from num.
    
    >>> get_strnum(8)
    (8, '8')
    """
    return (num, str(num))

def makeop(op, (num1, str1), (num2, str2)):
    """Make operation op between two string numbers.
    
    Return a tuple with the numerical result and the string representation 
    of that operation
    
    >>> makeop(operator.mul, (2, "(1+1)"), (6, "(2*3)"))
    (12, '((1+1)*(2*3))')
    """
    operator_string = {operator.add: "+", operator.sub: "-",
        operator.mul: "*", operator.div: "/"}
    outstr = "(" + str1 + operator_string[op] + str2 + ")"
    return op(num1, num2), outstr     

def process_pair(numstr1, numstr2):
    """Return all possible results from operating two values.
    
    >>> process_pair((7, "7"), (3, "3"))
    [(7, '7'), (3, '3'), (10, '(7+3)'), (21, '(7*3)'), (4, '(7-3)')]
    """
    if numstr1[0] < numstr2[0]:
        numstr1, numstr2 = numstr2, numstr1
    num1, num2 = numstr1[0], numstr2[0]
    output = [numstr1, numstr2]
    get = lambda op: makeop(op, numstr1, numstr2)
    output.append(get(operator.add))
    output.append(get(operator.mul))
    if num1 > num2:
        output.append(get(operator.sub))
    if (num1 % num2) == 0:
        output.append(get(operator.div))
    return output
          
def process(final, numstrs, show_approx=False):
    """Recursive function to search 'final', making operations on numstrs.
    
    Numstrings are tuples containing (integer_value, operation_string)
    
    >>> process(576, map(get_strnum, [1, 2, 3, 4, 5, 6]))
    (576, '(((4*(2+1))*6)*(5+3))')
    """
    for i1 in xrange(len(numstrs)):
        for i2 in xrange(i1+1, len(numstrs)):
            other_numstrs = numstrs[:i1] + numstrs[i1+1:i2] + numstrs[i2+1:] 
            for numstr in process_pair(numstrs[i1], numstrs[i2]):
                if numstr[0] == final:
                    return numstr
                if show_approx:
                    _show_approximation(final, numstr)
                numstr = process(final, [numstr] + other_numstrs)
                if numstr:
                    return numstr         
    
def _show_approximation(final, (x, strx)):
    """Calculate difference with the current best approximation. 
    Uses a global variable (best)"""
    global best
    if best is None or abs(final-x) < abs(final-best):
        best = x
        print "approx: %d = %s [delta=%d]" % (best, strx, abs(final-x))
    
def _test():
    """Run tests on docstrings"""
    import doctest
    return doctest.testmod(verbose=True)
    
def _main(args0):
    """Process options and arguments"""
    usage = "usage: cifras.py number1 ... numberN final\n    %s" % __doc__.strip()
    parser = optparse.OptionParser(usage)
    parser.add_option('-t', '--test', dest='test', default=False,
        action="store_true", help='Run unittests')        
    options, args = parser.parse_args(args0)
    if options.test:
        return _test()
    nums0 = map(int, args)
    if len(args) < 2:
        parser.print_help()
        return 1
    nums, final = nums0[:-1], nums0[-1]
    result = process(final, map(get_strnum, nums), show_approx=True)
    if result:
        print "%d = %s" % (final, result[1])
    else: print "Couldn't find the number %d" % final
                
if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))   
