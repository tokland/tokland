# Poor man's Algebraic Data Types for Ruby.
#
# Example: a tree in Haskell:
#
#   data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
# 
# May be written with ADT (broadly equivalent, no type checking):
# 
#   class Tree
#     include ADT
#     constructor :empty
#     constructor :leaf => :value
#     constructor :node => [:value, :left_tree, :right_tree]
#
#     def weight
#       case @type
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
module ADT  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def initialize(type, hash_arguments)
    @type = type
    hash_arguments.each do |key, value|
      instance_variable_set("@"+ key.to_s, value)
    end
    @instance_variables = [:type] + hash_arguments.map(&:first)
  end

  def ==(other_tree)
    @instance_variables.all? do |k|
      key = "@" + k.to_s
      self.instance_variable_get(key) == other_tree.instance_variable_get(key)
    end
  end  
    
  module ClassMethods  
    def constructor(arg)
      type, args = arg.is_a?(Hash) ? arg.first : [arg, []]
      self.send(:attr_accessor, type)      
      (class << self; self; end).send(:define_method, type) do |*cargs| 
        self.new(type, Array(args).zip(cargs))
      end
    end
  end
end
