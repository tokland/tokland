# Introduction #

**Text processing** in languages like Python or Ruby is usually tackled with imperative techniques (see for example this [chapter](http://my.safaribooksonline.com/book/web-development/ruby/9780596157487/text-processing-and-file-management/i_sect14_d1e4607) in "Ruby best practices"). However, in RubyFunctionalProgramming I tried to show that the advantages of using the functional paradigm. Let's see how to apply FP in simple text processing.

# The basics #

Text processing can be implemented with [Finite-state machines](http://en.wikipedia.org/wiki/Finite-state_machine) (FSM). In a nutshell: each step of the processing consists of a transition from one state to another state depending on a event/condition.

We want to write a loop where a `state` and an element of the input (`x`, a collection of `xs`) yields the `new_state` and an (optional) element of the output (`y`, of the final collection of `ys`). In text processing, `xs` and `ys` are strings. Written as Ruby code, the functional abstraction we need might look like this:

```
ys = xs.state_map(initial_state) do |state, x|
  next_state = f(state, x)
  y = g(state, x)
  [next_state, y]
end
#=> Enumerator
```

# An example: a compact log of git #

Let's process the output of `git log` to display only the branch, commit and first line of each log. For this input:

```
commit 6ad25c2f3fdfdc373935d9dd00d5db8ab711bd08
Author: Arnau Sanchez <pyarnau@gmail.com>
Date:   Thu Mar 7 21:40:03 2013 +0100

    second change

commit 5bb2d7c3266785f25339bbc188a880ab072d102e
Author: Arnau Sanchez <pyarnau@gmail.com>
Date:   Thu Mar 7 21:32:45 2013 +0100

    first upload
```

We want, being in the branch _master_, this output:

```
[master 6ad25c2f] second change
[master 5bb2d7c3] first upload
```

A possible implementation:

```
module Enumerable
  def state_map(initial_state, &block)
    Enumerator.new do |enum|
      reduce(initial_state) do |current_state, x|
        new_state, y = yield([current_state, x])
        enum.yield(y) unless y.nil?
        new_state
      end
    end
  end
end

class Git
  def self.compact_log
    branch = %x{git rev-parse --symbolic-full-name --abbrev-ref HEAD}.strip
    log_lines = %x{git log}.lines

    log_lines.state_map({:key => :find_commit}) do |state, line|
      case state[:key]
      when :find_commit
        case line
        when /^commit/
          [{:key => :find_log, :commit => line.split[1][0, 8]}, nil]
        else
          [state, nil]
        end
      when :find_log
        case line
        when /^ /
          output_line = "[#{branch} #{state[:commit]}] #{line.strip}"
          [{:key => :find_commit}, output_line]
        else
          [state, nil]
        end
      end
    end
  end
end

Git.compact_log.each { |line| puts line }
```

Note how the use of `case` splits the logic clearly. We first check which state are we in, and only then check the relevant conditions to decide the next state and the output. One could argue that this approach is a bit verbose; let's see a how it would look if state and input conditions are done all at once:

```
class Git
  def self.compact_log
    branch = %x{git rev-parse --symbolic-full-name --abbrev-ref HEAD}.strip
    log_lines = %x{git log}.lines

    log_lines.state_map({:key => :find_commit}) do |state, line|
      if state[:key] == :find_commit && line.match(/^commit/)
        [{:key => :find_log, :commit => line.split[1][0, 8]}, nil]
      elsif state[:key] == :find_log && line.match(/^ /)
        output_line = "[#{branch} #{state[:commit]}] #{line.strip}"
        [{:key => :find_commit}, output_line]
      else
        [state, nil]
      end
    end
  end
end
```

# Bonus: pattern-matching #

Functional languages provide [pattern-maching](http://en.wikipedia.org/wiki/Pattern_matching), an extremely useful construct in which one can, at the same time, perform a conditional, deconstruct values and bind them to variables.

Pattern-matching is specially useful when used with Algebraic Data Types (see RubyAlgebraicDataTypes). Using that module and the gem [pattern-match](https://github.com/k-tsj/pattern-match) we can rewrite the previous code like this:

```
require 'pattern-match'
require 'adt'

class Git
  def self.compact_log
    branch = %x{git rev-parse --symbolic-full-name --abbrev-ref HEAD}.strip
    log_lines = %x{git log}.lines

    states = adt(:FindCommit => [], :FindLog => [:commit])
    log_lines.state_map(states::FindCommit.new) do |state, line|
      match [state, line.rstrip] do
        with _[states::FindCommit, /commit (\w+)/.(commit)] do
          [states::FindLog.new(:commit => commit[0, 8]), nil]
        end
        with _[states::FindLog.(:commit => commit), / +(.*)/.(message)] do
          output_line = "[%s %s] %s" % [branch, commit, message]
          [states::FindCommit.new, output_line]
        end
        with _ do
          [state, nil]
        end
      end
    end
  end
end
```