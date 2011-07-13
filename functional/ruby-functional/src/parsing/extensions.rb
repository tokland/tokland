module Enumerable
  def map_compact(&block)
    self.map(&block).compact
  end

  def mash(&block)
    self.inject({}) do |hash, item|
      result = block_given? ? yield(item) : item
      key, value = result
      result ? hash.merge(key => value) : hash
    end
  end

  def map_detect(value_for_no_matching = nil)
    self.each do |member|
      if result = yield(member)
        return result
      end
    end
    value_for_no_matching
  end  
end

class Hash
  def slice(*keys)
    self.select { |k, v| keys.include?(k) }.mash
  end
end
