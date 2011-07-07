class Array
  def quicksort1
    return [] if self.empty?
    pivot, *other = self
    lesser = other.select { |x| x <= pivot }
    greater = other.select { |x| x > pivot }
    lesser.quicksort + [pivot] + greater.quicksort
  end

  def quicksort1b
    unless (pivot = self.first)
      []
    else
      other = self.drop(1)
      lesser = other.select { |x| x <= pivot }
      greater = other.select { |x| x > pivot }
      lesser.quicksort + [pivot] + greater.quicksort
    end
  end

  def quicksort2
    return [] if self.empty?
    pivot, *other = self
    lesser, greater = other.partition { |x| x <= pivot }
    lesser.quicksort + [pivot] + greater.quicksort
  end
  
  alias :quicksort :quicksort1b
end
