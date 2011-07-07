require './extensions'

class Num
  include Comparable
  attr_reader :value, :evaltree
   
  def initialize(value, evaltree = nil)
    @value = value
    @evaltree = evaltree || value
  end
  
  def inspect(result = true)
    string = @evaltree.is_a?(Hash) ? 
      "(" + [@evaltree[:num1].inspect(false), @evaltree[:method], @evaltree[:num2].inspect(false)].join + ")" : @evaltree
    result ? "#{@value} = #{string}" : string
  end
       
  [:+, :-, :*, :/, :%].each do |method|
    define_method(method) do |other|
      Num.new(@value.send(method, other.value), 
        {:method => method, :num1 => self, :num2 => other})
    end
  end
          
  def <=>(other)
    case other
    when Num then self.value <=> other.value
    else self.value <=> other
    end
  end        
end

#p Num.new(3)
#p Num.new(3) + Num.new(5)
#p x = (Num.new(3)+ Num.new(5))*Num.new(10)

class Problem
  def self.combine_pair(num1, num2)
    [
      num1 + num2,
      num1 >= num2 ? num1 - num2 : num2 - num1,
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
      (0..nums.size-1).to_a.combination(2).map_detect do |i1, i2|
        other = nums[0...i1] + nums[i1+1...i2] + nums[i2+1..-1]
        combine_pair(nums[i1], nums[i2]).map_detect do |new_number|
          solve((other + [new_number]), final)
        end
      end
    else
      nil
    end
  end
end

if __FILE__ == $0
  final, *nums = ARGV.map(&:to_i)
  p Problem.solve(nums.map { |n| Num.new(n) }, final)
end
