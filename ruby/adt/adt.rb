# Poor man's Algebraic Data ktypes for Ruby.
#
# Example: a tree in Haskell:
#
#   data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
# 
# May be written with ADT (broadly equivalent, no ktype checking):
# 
#   class Tree
#     include ADT
#     constructor :empty
#     constructor :leaf => :value
#     constructor :node => [:value, :left_tree, :right_tree]
#
#     def weight
#       case @ktype
#       when :empty then 0
#       when :leaf then 1
#       when :node then 1 + @left_tree.weight + @right_tree.weight
#     end
#   end
#
#  >> tree = Tree.node(1, Tree.leaf(2), Tree.empty)
#  >> tree.weight 
#  => 2
#

# To simplify case blocks in ADT class methods
class Symbol
  def ===(other) 
    other.instance_variable_get("@_adt_instance_variables") && 
      other.ktype === self || super 
  end
end

class Object
  # Like obj || fallback, but you decide which method to use as guard 
  #
  # Example: 
  #  [].or_if(:empty?) { ["default"] } #=> ["default"] 
  #  [1].or_if(:empty?) { ["default"] } #=> [1]
  def or_if(method, &block)
    self.send(method) ? yield(self) : self
  end
end

module ADT
  attr_accessor :ktype

  def self.included(base)
    base.extend(ClassMethods)
  end
      
  def initialize(ktype, hash_arguments)
    self.ktype = ktype
    hash_arguments.each do |key, value|
      self.class.send(:attr_accessor, key)
      self.send("#{key}=", value)
    end
    @_adt_instance_variables = [:ktype] + hash_arguments.map(&:first)
  end

  def ktype?(value)
    self.ktype == value
  end
  
  def ==(other)
    @_adt_instance_variables.all? do |k|
      key = "@" + k.to_s
      self.instance_variable_get(key) == other.instance_variable_get(key)
    end
  end
      
  module ClassMethods  
    def constructor(arg)
      ktype, args = arg.is_a?(Hash) ? arg.first : [arg, []]
      self.send(:attr_accessor, ktype)      
      (class << self; self; end).send(:define_method, ktype) do |*cargs| 
        self.new(ktype, Array(args).zip(cargs))
      end
    end
  end
end
