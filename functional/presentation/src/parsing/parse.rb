require './extensions'
require 'pp'
require 'ostruct'

class OpenStruct
  alias :attributes :marshal_dump
end

class Parsing
  attr_reader :people
  
  Fields = [[:id, :integer], [:name, :string], [:age, :integer], [:points, :float]]
  Types = {:string => :to_s, :integer => :to_i, :symbol => :to_sym, :float => :to_f}

  def initialize(people)
    @people = people
  end
  
  def self.new_from_file(path)
    people = open(path).each_line.map do |line|
      values = line.split(";")
      attributes = Fields.zip(values).mash do |(name, type), value|
        [name, value.strip.send(Types[type])]
      end
      OpenStruct.new(attributes)
    end
    Parsing.new(people)
  end
end

require 'pp'
parsing = Parsing.new_from_file("data.txt")
pp parsing.people

# use OpenStruct instead of hash

# total points of people over 30 years
class Parsing
  def problem2
    total = people.select do |person|
      person.age > 30
    end.map do |person| 
      person.points
    end.inject(0, :+)
  end

# but what about list-comprehensions?
# [person[:points] | person <- people, person[:age] > 30] Ruby/Haskell

  def problem2b
    total = people.map do |person|
      if person.age > 30
        person.points
      end
    end.compact.inject(0, :+)
  end
  # map_select -> map_compact, similar to list-comprehension
end

p parsing.problem2
p parsing.problem2b
exit

# implement Enumerable#sum
module Enumerable
  def sum
    self.inject(0, :+)
  end
end

# is there any person with more than 1500$ ?

# name of the first person (ordered by age ASC) that has more than 1500$

person = people.sort_by(&:age).detect do |person|
  person.points > 1500
end 
p person.name if person

#version2

person_name = people.sort_by(&:age).map_detect do |person|
  person.name if person.points > 1500
end 
p person_name # no if

# which is the pair with more points difference

# imperative
pair = nil
max_diff = nil
people.each do |person1|
  people.each do |person2|
    next if person1 == person2
    diff = (person1.points - person2.points).abs
    if !max_diff || diff > max_diff
      max_dif = diff
      pair = [person1, person2]
    end
  end
end
p pair.map(&:name)

pair = people.combination(2).max_by do |p1, p2|
  (p1.points - p2.points).abs
end
p pair.map(&:name)
exit

# talk about combination, permutation, (cartessian) product


# what if they ask now also what's the difference?

max_diff, names = people.combination(2).map do |p1, p2|
  diff = (p1.points - p2.points).abs
  [diff, [p1.name, p2.name]]
end.max

# convert to JSON with {id: {name: ..., age: ...}} 
require 'json'
data = people.mash do |person|
  [person.id, {:name => person.name, :age => person.age}]
  #[person.id, person.attributes.slice(:name, :age)]
end
puts JSON::pretty_generate({:data => data})

# duplicate points for people with odd age
new_people = people.map do |person|
  if person.age.odd?
    OpenStruct.new(person.attributes.merge(:points => person.points * 2))
  else
    person
  end
end
pp new_people
