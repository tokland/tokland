#!/usr/bin/python
"""
Simple math game: given a list of numbers, use the four basic 
operations (+, -, /, *)  to find (or be as close as possible to) 
another given number.

This code takes a functional (FP) approach. The Num class is used as
data container but no logic methods (more than repr) are implemented inside.

This problem was popularize first by the TV quiz-show "Des Chiffres et 
des Lettres" at France, and has travelled around ("Countdown" in the UK, 
"Cifras y Letras" in Spain, ...).

Author: Arnau Sanchez <tokland@gmail.com>
"""
import sys
import operator
import itertools

# Data model: an orthodox implementation would build a binary-tree,
# let's just save the string representation of the operation for simplicity.

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

def compact(it):
    return itertools.ifilter(bool, it)

def process_pair(num1, num2):
    """Yield all possible results from operating two nums. 
    
    Valid operations are: n1+2, n1*n2, n1-n2 (if n1 > n2), n2-n1 (if n2 > n1), 
        n1/n2 (if n1 is divisible by n2), n2/n1 (if n2 is divisible by n1).
    
    >>> list(process_pair(Num(7, "7"), Num(3, "3")))
    [Num(10, '(7+3)'), Num(4, '(7-3)'), Num(21, '(7*3)')]
    """
    num1a, num2a = ((num1, num2) if num1.value >= num2.value else (num2, num1))
    candidates = [
        (operator.add, None),
        (operator.sub, lambda x, y: x > y), 
        (operator.mul, None),
        (operator.div, lambda x, y: x % y == 0),
    ]
    # is it worth to remove duplicates?
    for (op, condition) in candidates:
        if not condition or condition(num1a.value, num2a.value):
            yield makeop(op, num1a, num2a)
                  
def process(ints):
    """Yield all possible numbers combinating pairs.
        
    >>> next(n for n in process([1,2,3,4,5,6]) if n.value == 576)
    Num(576, '(((4*(2+1))*6)*(5+3))')
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
    elif len(args) < 2:
        parser.print_help()
        return 1    
    all_nums = map(int, args)
    nums, final = all_nums[:-1], all_nums[-1]
    solutions = (res for res in process(nums) if res.value == final)
    for index, result in enumerate(itertools.islice(solutions, options.nsolutions or None)):
         print "%s. %d = %s" % (index+1, result.value, result.string)
                
if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
