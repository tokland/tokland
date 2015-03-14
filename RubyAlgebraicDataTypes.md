# Introduction #

Algebraic data types (ADT) is a powerful abstraction commonly found in functional languages. A binary tree, for example, it may be defined this way in Haskell:

```
data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)
```

![http://mousely.com/wiki_image/d/df/Binary_tree.png](http://mousely.com/wiki_image/d/df/Binary_tree.png)

```
Node 2 (Node 7 (Leaf 2) 
               (Node 6 (Leaf 5) 
                       (Leaf 11))) 
       (Node 5 Empty 
               (Node 9 (Leaf 4) 
                       Empty))
```

Wouldn't it be nice to make something similar with Ruby?

# A OOP with case classes #

In a standard OOP approach we would create a `Tree` parent class and a child class for each specific type of `Tree` (where we'd write the specific implementation of each method). Let's use a different approach, let's write methods only in the parent class and use a `case` block to match the type. That's how it would look:

```
Tree = adt(:Empty => [], :Leaf => [:value], :Node => [:value, :left_tree, :right_tree]) do
  def to_s
    case self
    when Tree::Empty
      "Empty"
    when Tree::Leaf
      "(Leaf #{value})"
    when Tree::Node
      "(Node #{value} #{left_tree} #{right_tree})"
    end    
  end
end

tree = Tree::Node.new(1, Tree::Leaf.new(2), 
                      Tree::Node.new(3, Tree::Empty.new, 
                                        Tree::Leaf.new(4)))
#=> (Node 1 (Leaf 2) (Node 3 Empty (Leaf 4)))
```

The code: https://gist.github.com/tokland/871431