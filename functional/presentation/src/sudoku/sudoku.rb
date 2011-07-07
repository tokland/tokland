require 'set'
require './extensions'

class Sudoku
  attr_reader :alternatives
  
  Columns = ("A".."I").to_a
  Rows = ("1".."9").to_a
  Squares = Columns.product(Rows).map(&:join).to_set
  Values = (1..9).to_set
    
  SubSquares = Columns.each_slice(3).map do |column|    
    Rows.each_slice(3).map do |row|
      column.product(row).map(&:join).to_set 
    end
  end
   
  Relations = Columns.product(Rows).map do |column, row|
    square = column + row
    related_squares = Rows.map { |r| column + r }.to_set +
      Columns.map { |c| c  + row }.to_set +
      SubSquares[Columns.index(column)/3][Rows.index(row)/3] -
      [square].to_set
    [square, related_squares]
  end.mash
          
  def initialize(alternatives)
    @alternatives = alternatives  
  end
  
  def solve
    p "---"
    p self
    p "---"
    return if @alternatives.any? { |sq, values| values.empty? }
    return self if @alternatives.all? { |sq, values| values.size == 1 }
    
    @alternatives.sort_by do |square, values| 
      [values.size, square]
    end.map_detect do |square_to_test, possible_values|
      if possible_values.size >= 2
        possible_values.sort.map_detect do |value_to_test|
          new_alternatives = Relations[square_to_test].mash do |sq| 
            new_possible_values = @alternatives[sq] - [value_to_test].to_set
            [sq, new_possible_values]
          end
        
          new_alternatives2 = @alternatives.
            merge(new_alternatives.merge(square_to_test => [value_to_test].to_set))
            
          condition1 = Columns.all? do |c|
            xs = [c].product(Rows).map do |c, r|
              new_alternatives2[c+r].to_a.first if new_alternatives2[c+r].size == 1
            end.compact.flatten
            xs.size == xs.uniq.size
          end          

          condition2 = Rows.all? do |r|
            xs = Columns.product([r]).map do |c, r|
              new_alternatives2[c+r].to_a.first if new_alternatives2[c+r].size == 1
            end.compact.flatten
            xs.size == xs.uniq.size
          end

          condition3 = SubSquares.flatten(1).all? do |sqs|
            xs = sqs.map do |square|
              new_alternatives2[square].to_a.first if new_alternatives2[square].size == 1
            end.compact.flatten
            xs.size == xs.uniq.size
          end
            
          if condition1 && condition2 && condition3            
            new_sudoku = Sudoku.new(new_alternatives2)
            new_sudoku.solve
          end
        end
      end
    end
  end
  
  def inspect
    Rows.map do |row|
      Columns.map do |column|
        @alternatives[column + row].map(&:to_s).join(",")
      end.join(" ")
    end.join("\n")
  end
  
  def self.new_from_string(string, options = {})
    blank_square = options[:blank_square] || /./
    matrix = string.scan(/([\d#{blank_square}])/).flatten(1).each_slice(9)
    p matrix.to_a
    square_values = matrix.each_with_index.map do |row, row_index|
      row.each_with_index.map do |char, column_index|
        if char =~ /\d/
          square = Columns[column_index] + Rows[row_index]
          [square, char.to_i]
        end 
      end
    end.flatten(1).compact.mash

    already_set = square_values.map { |square, value| [square, [value].to_set] }
    empty = (Squares - square_values.keys).map do |square|
      not_possible = Relations[square].map do |sq| 
        square_values[sq]
      end.compact.flatten.to_set
      [square, (Values - not_possible).to_set]
    end
    alternatives = already_set.mash.merge(empty.mash)
    Sudoku.new(alternatives)
  end
end

require 'pp'
sudoku = Sudoku.new_from_string(File.read("s2.txt"), :blank_square => /\./)
p 1
pp sudoku.solve
p "-"
