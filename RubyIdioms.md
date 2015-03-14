This document shows some Ruby idioms, conventions and patterns, most of them accepted by the community, some of them personal. This is a work in progress, so feel free to email me or add a comment if you have any suggestion (tokland AT gmail.com).



# Idioms #

## General formatting ##

Choose a formatting style with readability as first goal, and stick to it. At the same time, break the rules when necessary ("a foolish consistency is the hobgoblin of little minds").

Novice programmers tend to overlook the importance of how the code looks, but as it's been extensively remarked, source code is meant for other people to read and understand, and only incidentally for machines to execute.

### Indentation ###

Use 2 spaces, no tabs, and never mix spaces and tabs. Keep your code under 80-100 char width whenever possible. The 80-char rule used to be important when terminals had severe size limitations, but it still holds today on account of readability.

### Whitespaces ###

  * Put an space after a comma:

```
def method(x, y)
  [x, y]
end
```

  * No spaces after or before a _(_, _[_ or _{_ (when it's a hash):

```
array = [1, 2, 3]

hash = {:a => 1, :b => 2}

def method(arg1, arg2, arg3)
  # method body
end
```

But use spaces to let the blocks breathe:

```
[1, 2, 3].map { |x| 2*x }
```

Note that some programmers **do** put spaces after "[" `[ 1, 2, 3 ]` and "{" `{ :a => 1 `}. You'll see this style throughout Rails code, for example. I don't recommend it, values seem to "float" due to that space.

### Naming ###

  * `PascalCase` for modules and classes.
  * `ALL_UPPER_UNDERSCORED` for constants (`PascalCase` are also accepted).
  * `lower_undercase` for everything else: methods, attributes, local variables.

### Blank lines ###

This is often overlooked, but blank lines define a layout of the code and it's very important to be consistent. The style I favour is:

  * Don't put blank lines between different indentation levels (the indentation itself should serve as visual hint).

  * Insert a blank line between definitions (`module`, `class`, `def`, ...) on the same level.

  * On a given level, insert blank lines only sparingly to separate logic blocks.

Example:

```
module Animals
  class Dog
    attr_accessor :name
    attr_accessor :color
    
    def initialize(name, color)
      self.name = name
      self.color = color
    end
    
    def bark
      "bark, bark"
    end
  end
  
  class Cat
    ...
  end
end
```

## Blocks ##

Single line blocks are written with brackets:

```
obj.method { |foo| ... }
```

Multi-line blocks are written with _do/end_:

```
obj.method do |foo|
  ...
  ...
end
```

Some programmers [have proposed](http://weblog.raganwald.com/2007/11/programming-conventions-as-signals.html) to use brackets for functional blocks and _do/end_ for blocks with side-effects. While I find the idea interesting, brackets on multi-line blocks look weird, so I wouldn't recommend this style.

## Multi-line array/hashes ##

There are many ways of writing multi-line array or hashes. I recommend this style:

```
array = [
  1,
  2,
  3,
]
```

Note that we insert a comma also after the last element. This is very handy because we have not to worry if we are in the last line or no (and you can reorder without further editing). The same idea applies for hashes or the combination of both:

```
data = {
  :a => 1,
  :b => { 
    :b1 => "11",
    :b2 => "12",
  },
  :c => [
    "hello",
    "there",
  ],
}
```

## Implicit return value ##

Ruby, as does Lisp and many functional languages, return implicitly the last expression of a body (block/method). You can write an explicit `return` but that's considered to be non-idiomatic. So instead of:

```
  def add(x, y)
    return x + y
  end
```

Write always:

```
  def add(x, y)
    x + y
  end
```

## Parentheses ##

Parentheses on method definitions/calls are (usually) optional in Ruby. But my personal advice is to write them. The only valid exception I can think of are:

  * Calls without arguments (in fact it's extremely unidiomatic if you write them): `"3".to_i`.
  * DSL-style calls (`belongs_to :user`).

## Method name qualifiers ##

If your method returns a boolean, end it with _?_:

```
dog.hungry?
```

If your method does something "dangerous" (an in-place operation, or it may raise an exception on errors, or it's destructive, etc), you may end it with _!_:

```
database.destroy!
```

## Testing for truth values ##

No, no, no:

```
if !some_object.nil?
  ...
end
```

Yes:

```
if some_object
  ...
end
```

Ruby's objects are always truish except for `nil` and `false`, so the only valid reason to write the verbose `object.nil?` would be for telling `nil` from `false`, something hardly needed.

## Method arguments ##

No:

```
def method(arg1, arg2, arg3=1, arg4="hello", arg5="bye")
  ...
end
```

Yes:

```
def method(arg1, arg2, options = {})
  options = {
    :arg3 => 1,
    :arg4 => "hello",
    :arg5 => "bye",
  }.merge(options)
  ...
end
```

Or using Rails' [reverse\_update](http://rubydoc.info/docs/rails/Hash:reverse_update):

```
def method(arg1, arg2, options = {})
  options.reverse_update({
    :arg3 => 1,
    :arg4 => "hello",
    :arg5 => "bye",
  })
  ...
end
```

Why:

  * It clearly separates required from optional arguments.
  * You don't have to write intermediate arguments to reach the one you want.
  * You'll get a shorter (and cleaner) method signature. Long signatures are a nightmare to read.

Downside:

  * Available options are explicit in code but not in documentation.

Fortunately this is not a problem anymore in Ruby 2.0, we have Python-style keyword arguments.

## Calling methods with key arguments ##

It's not necessary to use explicit brackets to pass a hash as argument:

```
dog.bark(:volumen => 10, :duration => 5)
```

However, if there are lots of options and the line is too long, I recommend this multi-line style with brackets:

```
dog.bark({
  :volumen => 10, 
  :duration => 5,
  :direction => :ne,
})
```

## Unpack enumerables in block arguments ##

No:

```
[[1, 2], [3, 5]].map do |array|
  array[0] - array[1]
end # [1, 2]
```

Yes:

```
[[1, 2], [3, 5]].map do |v1, v2|
  v2 - v1
end # [1, 2]
```

Note that you can expand as nested levels as you need to using parenthesis:

```
[["hello", [2, 3.3]], ["bye", [4, 1.1]]].map do |string, (integer, float)|
  ...
end
```

## Use an script both as library or executable ##

```
if __FILE__ == $0
  # this script was not imported but executed, do something interesting here
end
```

## Catch-all rescue's ##

```
author_name = Book.find(book_id).author.name rescue nil
```

While common to see, I think this is not acceptable. A silent and indiscriminate `rescue` catches errors of all kinds (not only the ones you have in mind!), so it becomes a hard-to-debug source of bugs. Just don't do it.

Then how should we write this code without filling it with conditionals? check the section that covers the "maybe" pattern.

## Use expressions instead of statements ##

Instead of:

```
if hour > 10
  greeting = "hello"
else
  greeting = "bye"
end
```

You may write:

```
greeting = if hour > 10
  "hello"
else
  "bye"
end
```

This tend to cause some confusion amongst novices because conditionals are statements in mainstream languages (C, Python, Java, Javascript, ...). The advantages are: 1) the variable name is not repeated, 2) The intent of the code is more clear, it returns a "greeting" value (hopefully with no side-effects), you don't have to inspect the code details to know that.

## Trailing conditional statements ##

Use them sparingly, if the line is long the condition may be overlooked by the reader. An accepted usage is as guards for early returns:

```
def fun(arg1, arg2):
  return unless arg1 && arg2
  # body code
end
```

# Functional Ruby #

Ruby is not a functional language. In fact, being a classic OOP language it tacitly promotes changes in the state of objects. But, at the same time, Ruby comes with great functional capabilities.

This section was getting pretty long, so I moved it to its own page: [RubyFunctionalProgramming](RubyFunctionalProgramming.md).

# Build your own toolbox #

## Add your own extensions ##

So you have a dog named Scooby and want to know if it's in your list of selected dogs. You would probably write:

```
["rantanplan", "milu"].include?("scooby") #=> false
```

Notice how we the code reverse the phrasing of the problem. Why don't we create an abstraction that reflects how we think about the problem?

```
class Object
  def in?(enumerable)
    enumerable.include?(self)
  end
end
```

```
"scooby".in?(["rantanplan", "milu"]) #=> false
```

If you can't read aloud a line or code, or it sound funny, chanced are you should abstract it somehow.

## Use blocks as wrappers ##

```
tries = 0
result = begin
  get_result(1, 2)
rescue Exception1, Exception2 => error
  tries += 1
  retry unless tries > 5
  nil
end
```

There is nothing really wrong with this snippet, but look at the relevant code: `process` is buried in a jumble of infrastructure. Let's abstract the high-level construction so: 1) we simplify the code, and 2) we create a method that could be reused in this same or other projects:

```
result = retry_on_exceptions([Exception1, Exception2], :max_retries => 5) do
  get_result(1, 2)
end
```

In this second version you see right away what's going on. This example introduces a very useful pattern: using blocks as high-level wrappers. The more generic the pattern, the more reason you should abstract it. This is nothing new, wrappers with callbacks are used in many languages, but the difference with Ruby is that is very easy to send anonymous pieces of code as blocks.

## Some abstractions ##

### Managing nil's. The Maybe pattern ###

You've find a lost dog and you want to know where he lives. You'll write:

```
dog_address = dog.owner.address
```

But hey, there are street dogs with no owners, right? Then you should be careful and do this instead:

```
dog_address = dog.owner ? dog.owner.address : nil
```

Not nice, but we can live with it. But what happens if the chain continues? let's say we want to know which city the dog comes from:

```
dog_address = dog.owner ? dog.owner.address : nil
dog_address_city = dog_address ? dog_address.city : nil
```

Wow, this is getting worse, we should try to identify a pattern to simplify this code. There are two commonly proposed approaches to solve this:

  * Use a wrapper: Activesupport's Object#try.

```
require 'active_support/core_ext/object/try'
dog_owner_street = dog.owner.try(:address).try(:street)
```

  * Use a proxied object: Ick's Object#maybe.

Rails' `try` is not bad, but some programmers don't like seeing that their usual `object.method(arg1, ...)` turned into `object.wrapper(:method, arg1, ...)`. [Ick](http://ick.rubyforge.org/)'s maybe (or [andand](http://andand.rubyforge.org/), it's the same idea) takes the proxy approach: you simple call `maybe` to the object that _may be_ nil before the method call:

```
dog_owner_street = dog.owner.maybe.address.maybe.street
```

I'd recommend the second one, compact yet explicit.

### Enumerable#map\_select ###

Haskell popularized a very cool mathematical construction called _list comprehensions_. For example, to find out the squares of the first odd natural numbers between 1 and 10 you may write:

```
[x^2 | x <- [1..10], odd x]
```

Python borrowed it:

```
[x**2 for x in range(1, 10+1) if x % 2 == 1]
```

But, alas, Ruby has no such construction. However, we can build our poor man's list comprehension, as long as we define which value (usually nil) is to be filtered out from the output. That's how it would look:

```
(1..10).map_select { |x| x**2 if x.odd? }
```

Note that real list-comprehensions are more powerful, as they allow nested iterations.

```
module Enumerable
  def map_select(value_for_skip = nil)
    self.inject([]) do |acc, item|
      value = yield(item)
      value == value_for_skip ? acc : acc << value
    end
  end
end
```

### Enumerable#map\_detect ###

Simple exercise: find the first element in an array with a square greater than 10 and return this squared value. Options:

1) Simple: detect + operation:

```
n = [1,2,3,4].detect { |x| x**2 > 10 }
result = n ? n**2 : nil # 16
```

Booh, we needed to repeat the operation for the matching value and we also needed to control that it's not nil. Ugly.

2) map+first:

```
result = [1,2,3,4].map do |x| 
  square = x**2
  square if square > 10
end.compact.first # 16
```

That'd be conceptually ok in a lazy language, but Ruby maps the whole array, so we'll get very bad performance.

3) Our new abstraction Enumerable#map\_detect:

```
result = [1,2,3,4].map_detect do |x| 
  square = x**2
  square if square > 10 
end # 16
```

So our map\_detect is in fact a lazy version of the second example (map+compact+first). A possible implementation:

```
module Enumerable
  def map_detect(value_for_no_matching = nil)
    self.each do |member|
      if result = yield(member)
        return result
      end
    end
    value_for_no_matching
  end
end
```

### Object#presence ###

He have this code:

```
name = database_name || session_name || default_name
```

Now let's say that those values may be an empty string (which Ruby considers it to be true) but you don't want empty strings as name. Activerecord's [presence](http://api.rubyonrails.org/classes/Object.html#method-i-presence) is the best solution, just "nullify" empty values:

```
name = database_name.presence || session_name.presence || default_name.presence
```

Of course you could have written:

```
name = [database_name, session_name, default_name].detect(&:present?)
```

But this would compute all values (|| on the other hand is lazy), and they may not be as cheap to calculate as the ones in this example.

### Object#as ###

Look at this code:

```
result = info[0] * info[1]
```

At first glance it's not clear what it is doing. What about:

```
width, height = info
area = width * height
```

Now this is better, we are getting the area of a rectangle. It's really good to give name to things. There is nothing wrong now, only that we needed an extra line to unpack the array. What about?:

```
area = info.as { |width, height| width * height }
```

It's a matter of taste, but I think this is also pretty clear. Another example:

```
sq = x**2
pair = [sq, sq+1]
```

Can be written as:

```
pair = (x**2).as { |sq| [sq, sq+1] }
```

The implementation of Object#as is straightforward:

```
class Object
  def as
    yield self
  end
end
```

# What is beautiful code? #

  * It's simple.
  * It's readable.
  * It abstracts repeated patterns (Don't repeat yourself!).
  * It uses the right algorithms...
  * ...but does not sacrifice clarity for efficiency.
  * It's generic and reusable...
  * ...but compact and understandable.
  * It contains complexity instead of spreading it.

Ugly code breeds ugly code. Beautiful code breeds more beautiful code.

# Conclusion #

  * Write beautiful code. This is valid for any language, but while some just keep getting in your way no matter how hard you try, that's not the case (or at least not often) with Ruby.

  * Don't worry about performance too soon: maintenance of code is a hard task, write simple code that works (caveat: this does not mean ill-conceived code with the wrong algorithms). Benchmark it to see where the bottlenecks are and refactor accordingly.

  * Ruby is not a functional language, and that's fine, but don't use it imperatively unless there is a good reason. Keep state and side-effects to a minimum.

  * Core developers can't forecast all your needs, don't content yourself with the existing toolbox. **Programming is about building abstractions**, your personal toolbox containing reusable patterns should be growing and improving with each project you write.

In a nutshell: tweak the language to fit your needs and write maintainable, beautiful, compact, semantically meaningful code (it might be great if it worked as expected... write tests!).