require './extensions'

class Num
  include Comparable # implement <=> and get <, >, >=, <=, ==, != for free
  # starship operator (comes from Ruby)
  # talk about <=> -1 (less than), 0 (, +1
  attr_reader :value, :string # no need for a writter/accessor
   
  def initialize(value, string = nil)
    @value = value
    # discuss 'expression tree'w as the "orthodox" solution and not strings
    @string = string || value.to_s
  end
  
  def inspect # or to_s?
    "#{@value} = #{@string}"
  end
       
  [:+, :-, :*, :/, :%].each do |method| # first implement some separately, then use metaprogramming
    define_method(method) do |other|
      Num.new(@value.send(method, other.value), "(#{@string}#{method}#{other.string})")
    end
  end
          
  def <=>(other) # needed by module Comparable
    case other
    when Num then self.value <=> other.value # discuss about comparison of string
    else self.value <=> other
    end
  end        
end

class Problem
  # + - * / 
  def self.combine_pair(num1, num2)
    [
      num1 + num2,
      ((num1 - num2) if num1 > num2), # discuss (...)
      ((num2 - num1) if num1 > num2),
      num1 * num2,
      ((num1 / num2) if num2 != 0 && (num1 % num2) == 0),
      ((num2 / num1) if num1 != 0 && (num2 % num1) == 0),
    ].compact
  end
  
  def self.solve(nums, final)
    solution = nums.detect { |n| n == final }
    if solution 
      solution 
    elsif nums.size > 1
      # talk about: (0..nums.size-1).to_a.combination(2).each do |i1, i2| + each + return
      (0..nums.size-1).to_a.combination(2).map_detect do |i1, i2|
        other = nums[0...i1] + nums[i1+1...i2] + nums[i2+1..-1]
        # when map, talk about [Num] + 2 map = [[[Num]]] -> + flatten(2) -> [Num]. And flat_map
        combine_pair(nums[i1], nums[i2]).map_detect do |new_number|
          solve((other + [new_number]), final)
        end
      end
    else
      nil # not strictly necessary, but more explicit
    end
  end
end

if __FILE__ == $0
  final, *nums = ARGV.map(&:to_i)
  # move this translation to solve?
  p Problem.solve(nums.map { |n| Num.new(n) }, final)
end
