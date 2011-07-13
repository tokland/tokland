require './lazy'

class Array
  def quicksort1
    return [] if self.empty?
    pivot, *other = self
    lesser = other.select { |x| x <= pivot }
    greater = other.select { |x| x > pivot }
    lesser.quicksort1 + [pivot] + greater.quicksort1
  end  
  
  def quicksort2
    return [] if self.empty?
    pivot, *other = self
    lesser, greater = other.partition { |x| x <= pivot }
    lesser.quicksort2 + [pivot] + greater.quicksort2
  end
  
  def quicksort3
    return [] if self.empty?
    pivot = self.first
    lesser, greater = self.lazy.drop(1).partition { |x| x <= pivot }
    lesser.quicksort3 + [pivot] + greater.quicksort3
  end  
end

p [4,1,6,3,2,5].quicksort3

# talk about real Quicksort (Hoare): in-place
# a lot of intermediate arrays
# here there is no way to make it TCO
