#!/usr/bin/python
"""Implement a Reverse Polish Notation Calculator.

See: http://en.wikipedia.org/wiki/Reverse_Polish_notation.

Author: Arnau Sanchez <tokland@gmail.com>. August 2008
"""
from cmd import Cmd
import subprocess
import operator
import sys
import re

def debug(line):
    """Write line string to standard error and flush"""
    sys.stderr.write(line + "\n")
    sys.stderr.flush()

class ReversePolishCalcError(Exception):
    pass

class ReversePolishCalc:
    """Reverse Polish Notation Calculator.
    
    >>> calc = ReversePolishCalc()
    >>> calc.insert_value(1.0)
    [1.0]
    >>> calc.insert_value(2.0)
    [1.0, 2.0]
    >>> calc.insert_value(6.0)
    [1.0, 2.0, 6.0]
    >>> calc.insert_value(9.0)
    [1.0, 2.0, 6.0, 9.0]
    >>> calc.pop()
    [1.0, 2.0, 6.0]
    >>> calc.operation(float.__mul__)
    [1.0, 12.0]
    >> calc.operation(float.__add__)
    [13.0]
    >> calc.clear()
    []
    """

    def __init__(self):
        """Initialize the calculator stack"""
        self.stack = []

    def pop(self, index=-1):
        """Discard one element from the stack"""
        if not self.stack:
            raise ReversePolishCalcError, "Stack is empty"
        try:
            del self.stack[index]
        except IndexError:
            errmsg = "Cannot pop element '%s' from stack" % index
            raise ReversePolishCalcError, errmsg
        return self.stack

    def clear(self):
        """Discard all elements in the stack"""
        del self.stack[:]
        return self.stack

    def operation(self, operation):
        """Make operation (should be callable) on last two values on stack"""
        if len(self.stack) < 2:
            errmsg = "Insufficient stack size to issue an operation"
            raise ReversePolishCalcError, errmsg
        try:
            value = operation(*self.stack[-2:])
        except ZeroDivisionError:
            raise ReversePolishCalcError, "Zero division raised"
        self.stack[-2:] = [value]
        return self.stack

    def insert_value(self, value):
        """Append a float number onto the stack"""
        self.stack.append(float(value))
        return self.stack

class InteractiveReversePolishCalc(Cmd):
    """
    Command-line Reverse Polish Notation Calculator.
    
    Available commands: 

    clear -> Clear the current stack.
    pop [INDEX] -> Remove an element from the stack.
    stack -> Display current stack.
    quit -> Quit the calculator.

    +|-|*|/ -> Issue an operation.
    any numeric value (ex: 10.23) -> Insert float number onto stack.
    """

    intro = __doc__.strip()
    prompt = ">> "
    operations = {
        "+": operator.add,
        "-": operator.sub,
        "*": operator.mul,
        "/": operator.div,
    }

    def __init__(self):
        """Initialize a Cmd class and set starting values for calculator"""
        Cmd.__init__(self)
        self.calc = ReversePolishCalc()

    def _debug_stack(self):
        """Display the current stack value on the debug channel"""
        debug("current stack: %s" % self.calc.stack)

    def _debug_calc_error(self, line):
        """Display an error from the RPN calc"""
        debug("RPN Calculator Error: %s" % line)

    def precmd(self, line):
        """This method is called after the line has been input but before
        it has been interpreted.
        """
        return line.strip()

    def do_quit(self, line):
        """Quit the calculator"""
        return True

    def do_shell(self, line):
        """Run a command on a shell"""
        subprocess.call(line, shell=True)

    def do_help(self, line):
        """Get help on commands.
        'help' or '?' with no arguments prints a list of commands for which help is available
        'help <command>' or '? <command>' gives help on <command>
        """
        Cmd.do_help(self, line)

    def do_pop(self, line):
        """Discard one element from the stack (by default, the last one)"""
        try:
            self.calc.pop(int(line) if line else -1)
        except ValueError:
            debug("Syntax error on pop operation: %s" % line)
        except ReversePolishCalcError, errmsg:
            self._debug_calc_error(errmsg)
        self._debug_stack()

    def do_stack(self, line):
        """Display current stack"""
        print self.calc.stack

    def do_clear(self, line):
        """Discard all elements in stack"""
        self.calc.clear()
        self._debug_stack()

    def default(self, line):
        """Capture operator inserts (+, -, *, /) or number"""
        if line == "EOF":
            return True
        elif line in self.operations:
            try:
                self.calc.operation(self.operations[line])
            except ReversePolishCalcError, errmsg:
                self._debug_calc_error(errmsg)
        elif re.match("[0-9.eE]+", line):
            try:
                self.calc.insert_value(float(line))
            except ValueError:
                debug("Invalid float value: %s" % line)
        else:
            debug("Unknown command: %s" % line)
        self._debug_stack()

    def emptyline(self):
        """Called when the user enters an empty line. Do nothing"""
        pass

def main(args):
    """Start the RPN interactive calculator"""
    calc = InteractiveReversePolishCalc()
    return calc.cmdloop()

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
