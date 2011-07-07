require 'rubygems'
require 'simple_memoize'

module Math
  def self.fibs(n)
    n < 2 ? 1 : fibs(n - 1) + fibs(n - 2)
  end
  #cmemoize :fibs
end

p Math::fibs(35)
