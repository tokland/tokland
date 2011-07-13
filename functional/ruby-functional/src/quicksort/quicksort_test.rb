require 'test/unit'
require 'quicksort'

class QuickSortTest < Test::Unit::TestCase
  def test_quicksort
    assert_equal [], [].quicksort
    assert_equal [1, 2, 3], [1, 2, 3].quicksort
    assert_equal [1, 2, 4, 5, 10], [5, 2, 1, 4, 10].quicksort
  end
end
