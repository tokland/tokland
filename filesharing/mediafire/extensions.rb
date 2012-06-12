require 'curl'

module Enumerable
  def map_compact(&block)
    self.map(&block).compact
  end

  def mash(&block)
    self.inject({}) do |hash, item|
      if (result = block_given? ? yield(item) : item)
        key, value = (result.is_a?(Array) ? result : [item, result])
        hash.update(key => value)
      else
        hash
      end
    end
  end

  def map_select
    self.inject([]) do |acc, item|
      value = yield(item)
      value.nil? ? acc : acc << value
    end
  end
  
  def map_detect
    self.each do |member|
      if (result = yield(member))
        return result
      end
    end
    nil
  end
end

class MaybeWrapper
  instance_methods.each { |m| undef_method m unless m == :object_id || m =~ /^__/ }

  def method_missing(*args, &block)
    nil
  end
end

class String
  def splitAt(idx)
    [self[0...idx], self[idx..-1]] 
  end
end

class Object
  def to_bool
    !!self
  end

  def whitelist(*valids)
    valids.include?(self) ? self : nil
  end

  def blacklist(*valids)
    valids.include?(self) ? nil : self
  end
  
  def send_if_responds(method_name, *args, &block)
    respond_to?(method_name) ? self.send(method_name, *args, &block) : nil
  end

  def or_else(options = {}, &block)
    if options[:if]
      self.send(options[:if]) ? yield : self
    else
      self || yield
    end
  end

  def state_loop(initial_value, &block)
    value = initial_value
    loop do
      value = (yield value) or break
    end
  end

  def in?(enumerable)
    enumerable.include?(self)
  end

  def not_in?(enumerable)
    !enumerable.include?(self)
  end

  def maybe(&block)
    if block_given?
      nil? ? nil : yield(self)  
    else
      nil? ? MaybeWrapper.new : self
    end
  end
  
  def die(message, code = 1)
    info = caller(0)[1].split(":").first(2).join(":")
    $stderr.puts("[#{info}] #{message}")
    exit(code)  
  end
end

class OpenStruct
  def self.new_recursive(hash)
    OpenStruct.new(hash.mash do |key, value|
      new_value = value.is_a?(Hash) ? OpenStruct.new_recursive(value) : value
      [key, new_value]
    end)
  end
end

class File
  def self.write(path, data)
    open(path, "w") { |f| f.write(data) }
  end
end 

class Object
  def catch_exceptions(exit_codes)
    yield
    0
  rescue => exc
    $stderr.puts("ERROR: #{[exc.class.name, exc.to_s].uniq.join(': ')}")
    exit_codes.map_detect do |exc_class, exc_code| 
      exc_code if exc.is_a?(exc_class)
    end or raise
  end 
end

module Curl
  def self.download_with_progressbar(destination, file_url)
    open(destination, "wb") do |fd|
      curl = Curl::Easy.new(file_url)
      pbar = nil
      curl.on_body { |data| fd.write(data) }
      curl.on_progress do |dl_total, dl_now, ul_total, ul_now|
        if dl_total > 0
          pbar ||= ProgressBar.new(destination, dl_total).tap do |pbar|
            pbar.format_arguments = [:title, :percentage, :bar, :stat_for_file_transfer]
          end
          pbar.set(dl_now)
        end 
        true
      end 
      curl.perform
      pbar.finish if pbar
    end
    destination
  end
end
