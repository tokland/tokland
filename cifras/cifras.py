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

def makeop(op, (num1, str1), (num2, str2)):
    """Make operation op between two string numbers.
    
    Return a tuple with the numerical result and the sring representation 
    of that operation"""
    operator_string = {operator.add: "+", operator.sub: "-",
        operator.mul: "*", operator.div: "/"}
    outstr = "(" + str1 + operator_string[op] + str2 + ")"
    return op(num1, num2), outstr     

def process_pair(numstr1, numstr2):
    """Return all possible results from operating two values"""
    if numstr1[0] < numstr2[0]:
        numstr1, numstr2 = numstr2, numstr1
    num1, num2 = numstr1[1], numstr2[2]
    output = [numstr1, numstr2]
    output.append(makeop(operator.add, numstr1, numstr2))
    output.append(makeop(operator.mul, numstr1, numstr2))
    if num1 > num2:
        output.append(makeop(operator.sub, numstr1, numstr2))
    if (num1 % num2) == 0:
        output.append(makeop(operator.div, numstr1, numstr2))
    return output
     
best = None

def show_approximation(final, (x, strx)):
    """Calculate difference with the current best approximation. Uses
    a global variable (best)"""
    global best
    if best is None or abs(final-x) < abs(final-best):
        best = x
        print "apprx: %d = %s [delta=%d]" % (best, strx, abs(final-x))
     
def process(final, numstrs):
    """Recursive function to search 'final', making operations on numstrs"""
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
    
def main(args0):
    """Process options and arguments"""
    usage = "usage: cifras.py number1 ... numberN final\n    %s" % __doc__.strip()
    parser = optparse.OptionParser(usage)
    options, args = parser.parse_args(args0)
    nums0 = map(int, args)
    nums, final = nums0[:-1], nums0[-1]
    result = process(final, [(n, str(n)) for n in nums])
    if result:
        print "%d = %s" % (final, result[1])
    else: print "Couldn't find the number %d" % final
                
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
