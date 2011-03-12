Tree 2 (Node 7 (Leaf 2) 
               (Node 6 (Leaf 5) 
                       (Leaf 11))) 
       (Node 5 Empty 
               (Node 9 (Leaf 4) 
                       Empty))

class Tree
  def initialize(type, value = nil, left_tree = nil, right_tree = nil)
    @type = type
    @value = value
    @left_tree = left_tree
    @right_tree = right_tree
  end
  
  def self.empty
    Tree.new(:empty)    
  end

  def self.leaf(value)
    Tree.new(:leaf, value)
  end 

  def self.node(value, left_tree, right_tree)
    Tree.new(:node, value, left_tree, right_tree)
  end 
  
  def weight
    case @type
    when :empty
      0
    when :leaf
      1
    when :node
      1 + @left_tree.weight + @right_tree.weight
    end  
  end
end

tree = Tree.node(
  1, Tree.leaf(2), 
     Tree.node(3, Tree.empty, 
                  Tree.leaf(4)))

p tree.weight
