#!/usr/bin/python
"""
Based on a simple math game: given a bunch of numbers, and using the basic 
operations (+, -, /, *)  between them, find (or be as close as possible to) 
another given number.
"""

# Arnau Sanchez <tokland@gmail.com>

import sys
import operator
import optparse

# Best current approximation
best = -1

def makeop(op, (num1, str1), (num2, str2)):
    """Make operation op between two string numbers.
    
    Return a tuple with the numerical result and the sring representation 
    of that operation
    
    >>> makeop(operator.mul, (2, "(1+1)"), (6, "(2*3)"))
    (12, '((1+1)*(2*3))')
    """
    operator_string = {operator.add: "+", operator.sub: "-",
        operator.mul: "*", operator.div: "/"}
    outstr = "(" + str1 + operator_string[op] + str2 + ")"
    return op(num1, num2), outstr     

def process_pair(numstr1, numstr2):
    """Return all possible results from operating two values"""
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
     
def show_approximation(final, (x, strx)):
    """Calculate difference with the current best approximation. 
    Uses a global variable (best)"""
    global best
    if best is None:
        return
    if abs(final-x) < abs(final-best):
        best = x
        print "approx: %d = %s [delta=%d]" % (best, strx, abs(final-x))
     
def process(final, numstrs):
    """Recursive function to search 'final', making operations on numstrs.
    
    Numstrings are tuples containing (integer, operation_string)
    
    >>> process(576, [(n, str(n)) for n in [1, 2, 3, 4, 5, 6]])
    (576, '(((4*(2+1))*6)*(5+3))')
    """
    for i1 in xrange(len(numstrs)):
        for i2 in xrange(i1+1, len(numstrs)):
            other_numstrs = numstrs[:i1] + numstrs[i1+1:i2] + numstrs[i2+1:] 
            for numstr in process_pair(numstrs[i1], numstrs[i2]):
                if numstr[0] == final:
                    return numstr
                show_approximation(final, numstr)
                numstr = process(final, [numstr] + other_numstrs)
                if numstr:
                    return numstr         

def test():
    import doctest
    global best
    best = None
    doctest.testmod(verbose=True)
    
def main(args0):
    """Process options and arguments"""
    usage = "usage: cifras.py number1 ... numberN final\n    %s" % __doc__.strip()
    parser = optparse.OptionParser(usage)
    parser.add_option('-t', '--test', dest='test', default=False,
        action="store_true", help='Run unittests')        
    options, args = parser.parse_args(args0)
    if options.test:
        return test()
    nums0 = map(int, args)
    if len(args) < 2:
        parser.print_help()
        return 1
    nums, final = nums0[:-1], nums0[-1]
    result = process(final, [(n, str(n)) for n in nums])
    if result:
        print "%d = %s" % (final, result[1])
    else: print "Couldn't find the number %d" % final
                
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))   
