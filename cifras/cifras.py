#!/usr/bin/python
"""
Based on a simple math game: given a list of numbers use the four basic 
operations (+, -, /, *)  between them to find (or be as close as possible to) 
another given number.

This code takes a functional (FP) approach. Class Num is used solely as
data container, no logic methods (more than repr) are implemented.

Spanish users will recall it as the widely known "Cifras y Letras" TV quiz-show

Author: Arnau Sanchez <tokland@gmail.com>
"""
import sys
import operator
import itertools

# Data model

class Num:
    """Number class with value and string representation."""
    def __init__(self, value, string=None):
        self.value = value
        self.string = string or str(value)
        
    def __repr__(self):
        return "Num(%s, %s)" % (str(self.value), repr(self.string))
            
# Functions
            
def makeop(operation, num1, num2):
    """Make operation between two Nums.
        
    >>> makeop(operator.mul, Num(2, "(1+1)"), Num(6, "(2*3)"))
    Num(12, '((1+1)*(2*3))')
    """
    op = operator
    operator_string = {op.add: "+", op.sub: "-", op.mul: "*", op.div: "/"}
    string = "(" + num1.string + operator_string[operation] + num2.string + ")"
    return Num(operation(num1.value, num2.value), string)     

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
    return itertools.ifilter(bool, 
        (_generator(ns1, ns2) if ns1.value > ns2.value else _generator(ns2, ns1)))
          
def process(ints):
    """Yield all possible numbers combinating pairs.
        
    >>> result = next(n for n in process([1,2,3,4,5,6]) if n.value == 576)
    >>> result.value, result.string    
    (576, '(((4*(2+1))*6)*(5+3))')
    """
    def _process(nums):
        for i1, i2 in itertools.combinations(range(len(nums)), 2): 
            other_nums = nums[:i1] + nums[i1+1:i2] + nums[i2+1:]
            for num in process_pair(nums[i1], nums[i2]):
                yield num
                for x in _process([num] + other_nums):
                    yield x
    nums = map(Num, ints)
    for x in itertools.chain(nums, _process(nums)):
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
    parser.add_option('-n', '--nsolutions', dest='nsolutions', default=1,
        type="int", help='Solutions to find (0 = all)')        
    options, args = parser.parse_args(args0)
    if options.test:
        return _test()
    if len(args) < 2:
        parser.print_help()
        return 1    
    nums0 = map(int, args)
    nums, final = nums0[:-1], nums0[-1]
    solutions = (res for res in process(nums) if res.value == final)
    for index, result in enumerate(itertools.islice(solutions, options.nsolutions or None)):
         print "%s. %d = %s" % (index+1, result.value, result.string)
                
if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
