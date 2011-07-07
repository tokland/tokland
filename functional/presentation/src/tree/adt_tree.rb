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
  
  def pretty_print
    # TODO
  end
  
  def inspect
    case @type
    when :empty then "Empty"
    when :leaf then "(Leaf #{@value.inspect})"
    when :node then "(Node #{@value.inspect} #{@left_tree.inspect} #{@right_tree.inspect})"
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

  # Return a new tree with its values mapped by a block 
  def insert(value)
    case @type
    when :empty
      Tree.leaf(value)
    when :leaf
      if value <= @value
        Tree.node(@value, Tree.leaf(value), Tree.empty)
      else
        Tree.node(@value, Tree.empty, Tree.leaf(value))
      end      
    when :node
      if value <= @value
        Tree.node(@value, @left_tree.insert(value), @right_tree)
      else
        Tree.node(@value, @left_tree, @right_tree.insert(value))
      end      
    end      
  end
  
  def include?(value)
    case @type
    when :empty then 
      false
    when :leaf then 
      @value == value
    when :node then 
      @value == value || @left_tree.include?(value) || @right_tree.include?(value)
    end      
  end

  def sorted_tree_include?(value)
    case @type
    when :empty then 
      false
    when :leaf then 
      @value == value
    when :node then 
      @value == value || (value <= @value ? @left_tree.include?(value) : @right_tree.include?(value))
    end      
  end
      
  def weight
    case @type
    when :empty then 0
    when :leaf then 1
    when :node then 1 + @left_tree.weight + @right_tree.weight
    end  
  end
end

tree = 
  Tree.node(5, Tree.leaf(1), 
               Tree.node(8, Tree.empty, 
                            Tree.leaf(10)))
#puts tree.inspect
#p tree.values
#p tree.fmap { |x| 2 * x }
#puts tree.weight
p tree.include?(8)
p tree.sorted_tree_include?(8)
#p tree.insert(9)
#p tree.insert(3)
#p Tree.leaf(10).insert(3)
