#!/usr/bin/ruby
# http://code.google.com/codejam/contest/dashboard?c=635101#s=p0
#
# Author: tokland@gmail.com

class Problem
  # Create a directory (as array of slugs) in an existing filesystem and 
  # return the final filesytem and the total creation cost.   
  def self.create_directory(filesystem, slugs)
    if head = slugs.first
      result = create_directory(filesystem[head] || {}, slugs.drop(1))
      new_cost = result[:cost] + (filesystem.has_key?(head) ? 0 : 1)
      {:filesystem => filesystem.merge(head => result[:filesystem]), :cost => new_cost}
    else
      {:filesystem => filesystem, :cost => 0}
    end
  end

  # Take an array of pre-existing directories and return the cost 
  # (number of new sub-directories) in order to create some other directories. 
  def self.create_directories(existing, to_create)
    initial = {:filesystem => {"" => {}}, :cost => 0}
    (existing + to_create).each_with_index.inject(initial) do |input, (directory, idx)|
      results = create_directory(input[:filesystem], directory.split("/"))
      new_cost = input[:cost] + (idx >= existing.size ? results[:cost] : 0)
      {:filesystem => results[:filesystem], :cost => new_cost}
    end
  end

  def self.solve(problem_lines)
    1.upto(problem_lines[0].to_i).inject(problem_lines.drop(1)) do |lines, idx|
      n, m = lines[0].split.map(&:to_i)
      directories = lines.drop(1).map(&:strip).take(n + m)
      cost = create_directories(directories[0...n], directories[n..-1])[:cost]
      puts "Case ##{idx}: #{cost}"
      lines.drop(n + m + 1)
    end
  end
end

Problem.solve(File.readlines(ARGV[0] || "A-small-practice.in"))
