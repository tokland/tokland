require './extensions'
require './lazy'

# lazy.rb: see http://redmine.ruby-lang.org/issues/4890

class Num
  include Comparable
  attr_reader :value, :string
   
  def initialize(value, string = nil)
    @value = value
    @string = string || value.to_s
  end
  
  def inspect
    "#{@value} = #{@string}"
  end
  
  def <=>(other)
    case other
    when Num then self.value <=> other.value
    else self.value <=> other
    end
  end        
    
  [:+, :-, :*, :/, :%].each do |method|
    define_method(method) do |other|
      Num.new(@value.send(method, other.value), "(#{@string}#{method}#{other.string})")
    end
  end  
end

class Problem
  def self.combine(num1, num2)
    [
      num1 + num2,
      num1 >= num2 ? num1 - num2 : num2 - num1,
      num1 * num2,
      ((num1 / num2) if num2 != 0 && (num1 % num2) == 0),
      ((num2 / num1) if num1 != 0 && (num2 % num1) == 0),
    ].compact
  end

  def self.solve(ns, final)
    generate(ns.map { |n| Num.new(n) }).select { |x| x == final }  
  end
  
private
  
  def self.generate(nums)
    if nums.size < 2
      nums
    else
      (0..nums.size-1).to_a.combination(2).lazy.flat_map do |i1, i2|
        other = nums[0...i1] + nums[i1+1...i2] + nums[i2+1..-1]
        combine(nums[i1], nums[i2]).lazy.flat_map do |new_number|
          generate((other + [new_number]))                        
        end
      end
    end
  end
end

Problem.solve([3, 7, 10, 7, 2, 5], 198).each_with_index do |solution, index|
  puts "#{index+1}. #{solution.inspect}"
end
