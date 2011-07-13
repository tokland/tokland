require './extensions'
# see http://redmine.ruby-lang.org/issues/4890

module Denumerable
  def map
    Denumerator.new do |output|
      each do |input|
        output.yield yield(input)
      end
    end
  end

  def flatten1
    Denumerator.new do |output|
      self.each do |xs|
        xs.each do |x|
          output.yield(x)
        end
      end
    end
  end
    
  def flat_map(&block)
    self.map(&block).flatten1
  end
end

module Enumerable
  def lazy
    Denumerator.new do |yielder|
      self.each do |x|
        yielder.yield(x)
      end    
    end
  end
end

class Denumerator < Enumerator
  include Denumerable
end

class Num
  attr_reader :value, :string
   
  def initialize(value, string = nil)
    @value = value
    @string = string || value.to_s
  end
  
  def inspect
    "#{@value} = #{@string}"
  end
    
  [:+, :-, :*, :/, :%].each do |method|
    define_method(method) do |other|
      Num.new(@value.send(method, other.value), "(#{@string}#{method}#{other.string})")
    end
  end
  
  def method_missing(method, *args, &block)
    @value.send(method, *args, &block)      
  end        
end

class Problem
  def self.combine(num1, num2)
    [
      num1 + num2,
      num1 >= num2 ? num1 - num2 : num2 - num1,
      num1 * num2,
      ((num1 / num2) if !num2.zero? && (num1 % num2).zero?),
      ((num2 / num1) if !num1.zero? && (num2 % num1).zero?),
    ].compact
  end
  
  def self.solve(nums, final)
    solution = nums.detect { |n| n.value == final }
    if solution
      [solution]
    elsif nums.size > 1
      (0..nums.size-1).to_a.combination(2).lazy.flat_map do |i1, i2|
        other = nums[0...i1] + nums[i1+1...i2] + nums[i2+1..-1]
        combine(nums[i1], nums[i2]).lazy.flat_map do |new_number|
          solve((other + [new_number]), final)                        
        end
      end
    else
      []
    end      
  end
end

Problem.solve([3, 7, 10, 50, 8].map { |n| Num.new(n) }, 148).each do |x|
  p x
end
