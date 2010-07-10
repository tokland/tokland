#!/usr/bin/python
"""
Based on a simple math game: given a list of numbers use the four basic 
operations (+, -, /, *)  between them to find (or be as close as possible to) 
another given number.

Functional approach, use generators and function. Class Num used solely as
data container, no logic methods are used.

Spanish users will recall it as the famous "Cifras y Letras" TV quiz-show

Author: Arnau Sanchez <tokland@gmail.com>
"""
import sys
import operator
import itertools

class Num:
    """Number class with value and string representation."""
    def __init__(self, value, string=None):
        self.value = value
        self.string = string or str(value)
        
    def __repr__(self):
        return "Num(%s, %s)" % (str(self.value), repr(self.string))
    
def first(it, default=None):
    """Return first element in iterator. Return 'default' if exhausted."""
    return next(it, default)
        
def makeop(op, num1, num2):
    """Make operation between two Nums.
        
    >>> makeop(operator.mul, Num(2, "(1+1)"), Num(6, "(2*3)"))
    Num(12, '((1+1)*(2*3))')
    """
    operator_string = {
        operator.add: "+", 
        operator.sub: "-",
        operator.mul: "*", 
        operator.div: "/"
    }
    outstr = "(" + num1.string + operator_string[op] + num2.string + ")"
    return Num(op(num1.value, num2.value), outstr)     

def process_pair(ns1, ns2):
    """Yield all possible results from operating two values. 
    
    Valid operations are: n1+2, n1*n2, n1-n2 (if n1 > n2), n2-n1 (if n2 > n1), 
        n1/n2 (if n1 is divisible by n2), n2/n1 (if n2 is divisible by n1).
    
    >>> list(process_pair(Num(7, "7"), Num(3, "3")))
    [Num(10, '(7+3)'), Num(4, '(7-3)'), Num(21, '(7*3)')]
    """
    def _process(ns1, ns2, op, conditionfunc=None):
        if not conditionfunc or conditionfunc(ns1.value, ns2.value):
            return makeop(op, ns1, ns2)
    def _generator(ns1, ns2):
        yield _process(ns1, ns2, operator.add)
        yield _process(ns1, ns2, operator.sub, lambda x, y: x > y) 
        yield _process(ns1, ns2, operator.mul)
        yield _process(ns1, ns2, operator.div, lambda x, y: x % y == 0)
    return itertools.ifilter(bool, _generator(ns1, ns2) if ns1.value > ns2.value 
                                                        else _generator(ns2, ns1))
          
def process(numstrs):
    """Yield all possible numbers combinating pairs.
        
    >>> result = first(n for n in process(map(Num, [1,2,3,4,5,6])) if n.value == 576)
    >>> result.value, result.string    
    (576, '(((4*(2+1))*6)*(5+3))')
    """
    for x in numstrs:
        yield x
    # We could use itertools.combinations with py>=2.6 
    for i1 in xrange(len(numstrs)):
        for i2 in xrange(i1+1, len(numstrs)):
            other_numstrs = numstrs[:i1] + numstrs[i1+1:i2] + numstrs[i2+1:] 
            for numstr in process_pair(numstrs[i1], numstrs[i2]):
                yield numstr
                for x in process([numstr] + other_numstrs):
                    yield x
        
def _test():
    """Run tests on docstrings"""
    import doctest
    return doctest.testmod(verbose=True)
        
def _main(args0):
    """Process options and arguments"""
    import optparse
    usage = "usage: cifras.py number1 ... numberN final\n\n" + __doc__.strip()
    parser = optparse.OptionParser(usage)
    parser.add_option('-t', '--test', dest='test', default=False,
        action="store_true", help='Run unittests')        
    parser.add_option('-v', '--verbose', dest='verbose', default=False,
        action="store_true", help='Enable verbose mode')        
    options, args = parser.parse_args(args0)
    if options.test:
        return _test()
    if len(args) < 2:
        parser.print_help()
        return 1    
    nums0 = map(int, args)
    nums, final = nums0[:-1], nums0[-1]
    result = first(n for n in process(map(Num, nums)) if n.value == final)
    if not result:
        print "Couldn't find number %d" % final
        return 2
    print "%d = %s" % (result.value, result.string)
                
if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
