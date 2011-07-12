require 'pp'
require 'ostruct'
require 'json'

require './extensions'

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
      values = line.split(";") # why not directly in the zip, explain. 
      # FP programs can be written, potentially, in 1 line
      attributes = Fields.zip(values).mash do |(name, type), value|
        [name, value.strip.send(Types[type])]
      end
      # use Struct instead of hash, more natural in Ruby
      OpenStruct.new(attributes)
    end
    Parsing.new(people)
  end
  
  def problem1
    @people.any? do |person|
      person.points > 1500
    end
  end
  
  def problem2
    @people.select do |person|
      person.age > 30
    end.map do |person|
      person.points
    end.inject(0, :+) # abstract Enumerable#sum
  end

  def problem2b
    @people.map do |person|
      if person.age > 30
        person.points
      end
    end.compact.inject(0, :+)
  end

  # list-comprehensions: haskell, python
  # [person[:points] | person <- people, person[:age] > 30] Ruby/Haskell
  def problem2c
    @people.map_compact do |person|
      if person.age > 30
        person.points
      end
    end.inject(0, :+) 
  end
  
  def problem3
    @people.group_by { |person| (person.age / 10) * 10 }.mash do |age, people_in_age|
      [age, people_in_age.map(&:points).inject(0, :+)]
    end
  end  
  
  def problem4
    person = @people.sort_by(&:age).detect do |person|
      person.points > 1500
    end
    person.name if person
  end

  def problem4b
    person_name = @people.sort_by(&:age).map_detect do |person|
      if person.points > 1500
        person.name
      end
    end    
  end
  
  def problem5_imperative  
    pair = nil
    max_diff = nil
    @people.each do |person1|
      @people.each do |person2|
        next if person1 == person2
        diff = (person1.points - person2.points).abs
        if !max_diff || diff > max_diff
          max_diff = diff
          pair = [person1, person2]
        end
      end
    end
    [pair[0].name, pair[1].name] if pair
  end

  def problem5
    pair = @people.combination(2).max_by do |person1, person2|  
      (person1.points - person2.points).abs
    end
    pair.map(&:name) if pair
  end

  def problem5b
    @people.combination(2).map do |person1, person2|  
      [(person1.points - person2.points).abs, [person1.name, person2.name]]
    end.max
  end
  
  def problem6
    people_hash = @people.sort_by(&:id).mash do |person|
      #[person.id, {:name => person.name, :age => person.age}] # abstract it
      [person.id, person.attributes.slice(:name, :age)]
    end
    JSON::pretty_generate({:people => people_hash})  
  end
  
  def problem7
    new_people = @people.sort_by(&:id).map do |person|
      if person.age.even?
        new_attributes = person.attributes.merge(:points => person.points * 2)
        OpenStruct.new(new_attributes)
      else
        person
      end
    end
    Parsing.new(new_people)
  end
end

parsing = Parsing.new_from_file("data.txt")
pp parsing.people
pp parsing.problem1
pp parsing.problem2
pp parsing.problem2b
pp parsing.problem2c
pp parsing.problem3
pp parsing.problem4
pp parsing.problem4b
pp parsing.problem5_imperative
pp parsing.problem5
pp parsing.problem5b
puts parsing.problem6
pp parsing.problem7
