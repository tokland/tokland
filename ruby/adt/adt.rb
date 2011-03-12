# Poor man's Algebraic Data Types for Ruby.
#
# Example: a tree in Haskell may be written:
#
# data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
# 
# Now in Ruby we can write this (broadly) equivalent (with no type checking):
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
module ADT
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def initialize(type, hash_arguments)
    @type = type
    hash_arguments.each do |key, value|
      instance_variable_set("@"+ key.to_s, value)
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

# Haskell: data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
class Tree
  include ADT
  constructor :empty
  constructor :leaf => :value
  constructor :node => [:value, :left_tree, :right_tree]
  
  # Return weight of tree (total number of non-empty nodes)
  def weight
    case @type
    when :empty then 0
    when :leaf then 1
    when :node then 1 + @left_tree.weight + @right_tree.weight
    end  
  end 

  # Return flatten array of values (from left to right) in a tree
  def values
    case @type
    when :empty then []
    when :leaf then [@value]
    when :node then [@value] + @left_tree.values + @right_tree.values
    end      
  end
    
  # Return a new tree with its values mapped by a block 
  def fmap(&block)
    case @type
    when :empty
      Tree.empty
    when :leaf
      Tree.leaf(yield(@value))
    when :node
      Tree.node(yield(@value), @left_tree.fmap(&block), @right_tree.fmap(&block))
    end      
  end
end

if __FILE__ == $0  
  tree = 
    Tree.node("1", Tree.leaf("1a"), 
                   Tree.node("1b", Tree.empty, 
                                   Tree.leaf("1bB")))
  p tree.weight #=> 4
  p tree.values #=> ["1", "1a", "1b", "1bB"]
  p tree.fmap { |x| "v=#{x}" }.values #=> ["v=1", "v=1a", "v=1b", "v=1bB"]
end
