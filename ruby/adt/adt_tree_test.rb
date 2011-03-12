require 'rubygems'
require 'test/unit'

require 'adt_tree'

class ADTTest < Test::Unit::TestCase
  def setup
    @tree = 
      Tree.node("1", Tree.leaf("1a"), 
                     Tree.node("1b", Tree.empty, 
                                     Tree.leaf("1bB")))
  end
  
  def test_weight
    assert_equal 4, @tree.weight
  end                                     

  def test_values
    assert_equal ["1", "1a", "1b", "1bB"], @tree.values
  end
  
  def test_fmap
    assert_equal ["v=1", "v=1a", "v=1b", "v=1bB"], 
                 @tree.fmap { |x| "v=#{x}" }.values
  end
  
  def test_inspect
    assert_equal "(Node 1 (Leaf 1a) (Node 1b Empty (Leaf 1bB)))", @tree.inspect
  end
  
  def test_tree_from_object
    assert_equal Tree.empty, Tree.from_object(nil)
    assert_equal Tree.leaf(1), Tree.from_object(1)
    assert_equal Tree.node(1, Tree.leaf(2), Tree.leaf(3)), 
                 Tree.from_object([1, [2, 3]])
    assert_equal Tree.node(1, Tree.empty, 
                              Tree.node(3, Tree.leaf(4), 
                                           Tree.leaf(5))),
                 Tree.from_object([1, [nil, [3, [4, 5]]]])
  end
  
  def test_tree_to_object
    assert_equal nil, Tree.empty.to_object
    assert_equal 1, Tree.leaf(1).to_object
    assert_equal [1, [2, 3]], Tree.node(1, Tree.leaf(2), Tree.leaf(3)).to_object
    assert_equal [1, [nil, [3, [4, 5]]]],
                 Tree.node(1, Tree.empty, 
                              Tree.node(3, Tree.leaf(4), 
                                           Tree.leaf(5))).to_object
                   
  end
end
