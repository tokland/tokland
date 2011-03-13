require 'adt'

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

# data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
#
# The Leaf constructor is not strictly necessary because a leaf could  
# be written (Node a Empty Empty), but this way it's more clear.
#
class Tree
  include ADT
  constructor :empty
  constructor :leaf => :value
  constructor :node => [:value, :left_tree, :right_tree]
  
  def inspect
    case self.ktype # .ktype is optional because Symbol#===(adt_type) is overridden
    when :empty then "Empty"
    when :leaf then "(Leaf #{@value.inspect})"
    when :node then "(Node #{@value.inspect} #{@left_tree.inspect} #{@right_tree.inspect})"
    end    
  end
    
  # Return weight of tree (total number of non-empty nodes)
  def weight
    case self
    when :empty then 0
    when :leaf then 1
    when :node then 1 + @left_tree.weight + @right_tree.weight
    end  
  end 

  # Return flatten array of values (from left to right) in a tree
  def values
    case self
    when :empty then []
    when :leaf then [@value]
    when :node then [@value] + @left_tree.values + @right_tree.values
    end      
  end
    
  # Return a new tree with its values mapped by a block 
  def fmap(&block)
    case self
    when :empty
      Tree.empty
    when :leaf
      Tree.leaf(yield(@value))
    when :node
      Tree.node(yield(@value), @left_tree.fmap(&block), @right_tree.fmap(&block))
    end      
  end
  
  def leaf_paths
    case self
    when :empty
      []
    when :leaf
      [[@value]]
    when :node
      (@left_tree.leaf_paths.map { |vs| [@value] + vs } +
       @right_tree.leaf_paths.map { |vs| [@value] + vs }).or_if(:empty?) { [[@value]] }
    end            
  end
  
  # Build a tree from a Ruby object. 
  #
  # nil -> Tree.empty
  # x -> Tree.leaf(x)
  # [v, [l, r]] -> Tree.node(v, l, r)
  def self.from_object(obj)
    case obj
    when nil
      Tree.empty
    when Array
      value, (left_tree, right_tree) = obj
      Tree.node(value, self.from_object(left_tree), self.from_object(right_tree))
    else
      Tree.leaf(obj)
    end
  end
  
  # Convert tree to Ruby object (inverse of Tree::from_object)
  def to_object
    case self
    when :empty then nil
    when :leaf then @value
    when :node then [@value, [@left_tree.to_object, @right_tree.to_object]]
    end
  end
end
