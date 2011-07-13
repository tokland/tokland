require './extensions'

class Num
  attr_reader :value, :string
   
  def initialize(value, string = nil)
    @value = value
    @string = string || value.to_s
  end
  
  def inspect
    "#{@value} = #{@string}"
  end
    
  [:+, :-, :*, :/].each do |method|
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
    Enumerator.new do |yielder|
      solution = nums.detect { |n| n.value == final }
      if solution
        yielder.yield(solution)
      elsif nums.size > 1
        (0..nums.size-1).to_a.combination(2).each do |i1, i2|             
          other = nums[0...i1] + nums[i1+1...i2] + nums[i2+1..-1]
          combine(nums[i1], nums[i2]).each do |new_number|
            solve((other + [new_number]), final).each do |x|
              yielder.yield(x)
            end
          end
        end
      end
    end
  end
end

Problem.solve([3, 7, 10, 50, 100, 8].map { |n| Num.new(n) }, 548).each do |x|
  p x
end
