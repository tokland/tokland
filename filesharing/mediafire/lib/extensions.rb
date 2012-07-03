require 'uri'
require 'curl'
require 'nestegg'
require 'progressbar'
require 'enumerable/lazy'

module Enumerable
  # [1, 2, 3].mash { |x| [x.to_s, 2*x] } #=> {"1"=>2, "2"=>4, "3"=>6}
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

  # [1, 2, 3].map_select { |x| 2*x if x > 1 } #=> [4, 6]
  def map_select
    self.inject([]) do |acc, item|
      value = yield(item)
      value.nil? ? acc : acc << value
    end
  end
  
  # [1, 2, 3].map_detect { |x| 2*x if x > 1 } #=> 4
  def map_detect
    self.each do |member|
      if (result = yield(member))
        return result
      end
    end
    nil
  end
end

class String
  # "  ".present? #=> false
  def present?
    !strip.empty?
  end

  # "hello".split_at(2) #=> ["he", "llo"]
  def split_at(idx)
    [self[0...idx] || "", self[idx..-1] || ""] 
  end
end

class MaybeWrapper
  instance_methods.each { |m| undef_method(m) unless m == :object_id || m =~ /^__/ }

  def method_missing(*args, &block)
    nil
  end
end

class Object
  def present?
    true
  end
  
  def blank?
    !present?
  end
  
  def presence
    self.present? ? self : nil
  end
  
  # [1, 2].as { |x, y| x + y } #=> 3
  def as
    yield self
  end
  
  # 1.to_bool #=> true
  # nil.to_bool #=> false
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
end

class FalseClass
  def present?
    false
  end
end

class NilClass
  def present?
    false
  end
end

class Array
  # [1].present? #=> true
  # [].present? #=> false
  def present?
    !empty?
  end

  # [0, 1, 2, 3].split_at(1) #=> [[0], [1, 2, 3]]
  def split_at(idx)
    [self[0...idx] || [], self[idx..-1] || []] 
  end
  
  def extract_options
    if last.is_a?(Hash)
      [self[0...-1], last]
    else
      [self, {}]
    end  
  end

  def lazy_slice(range)
    Enumerator.new do |yielder|
      range.each do |index|
        yielder << self[index]
      end
    end.lazy
  end
end  

class Hash
  def present?
    !empty?
  end
  
  def reverse_update(other_hash)
    replace(other_hash.merge(self))
  end
end

module Kernel
  def circular_accumulator(initial_value, &block)
    value = initial_value
    Enumerator.new do |yielder|
      while value
        yielder << value
        value = (yield value)
      end
    end
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
  def define_exceptions(*args)
    names, options = args.extract_options
    Array(names).each do |name|
      parent = options[:from] || Class.new(StandardError) do
        include Nestegg::NestingException
        
        def initialize(msg = nil, options = {})
          super(msg)
          @options = options
          @msg = msg
        end
        
        def to_s
          @msg
        end
      end
 
      const_set(name, parent)
    end
  end
end

class WrapClass
  def initialize(block, &module_block)
    singleton_class.send(:attr_accessor, :block)
    singleton_class.class_eval(&module_block)
    self.block = block
  end
end

module Kernel
  # lets("do some math") { 1 + 2*3 } #=> 7 
  def lets(msg = nil, &block)
    yield
  end

  # scope { |x = 1, y = 2| x + y } #=> 3
  def scope(&block)
    num_required = block.arity >= 0 ? block.arity : ~block.arity
    yield *([nil] * num_required)
  end
    
  def catch_exceptions(exit_codes)
    yield
  rescue => exc
    exit_codes.map_detect do |symbol_or_exc_class, exc_code|
      if symbol_or_exc_class.is_a?(Class) && exc.is_a?(symbol_or_exc_class) 
        $stderr.puts("ERROR: #{[exc.class.name, exc.to_s].uniq.join(' - ')}")
        exc_code
      end
    end or raise
  end
  
  # contents = guard { File.read("/etc/service") }.with({
  #   Errno::ENOENT => MyErrorFileNotFound.new("file not found"),
  #   Errno::EISDIR => proc { |exc| MyErrorIsDirectory.new("it's a directory: #{exc}") },
  # })
  def guard(&block)
    WrapClass.new(block) do
      def with(exceptions)
        begin
          block.call
        rescue *exceptions.keys => exc
          raise(*exceptions.map_detect do |from, to|
            if exc.is_a?(from) 
              to.is_a?(Proc) ? to.call(exc) : to
            end
          end)
        end
      end

      def with_values(exceptions)
        begin
          block.call
        rescue *exceptions.keys => exc
          exceptions.map_detect do |from, to|
            if exc.is_a?(from) 
              to.is_a?(Proc) ? to.call(exc) : to
            end
          end
        end
      end
    end
  end
  
  # circular_loop(1) { |x| x < 3 ? [:continue, x + 1] : [:break, x] } #=> 3
  def circular_loop(value)
    loop do
      action, new_value = yield(value)
      value = case action
      when :continue
        new_value
      when :break
        break new_value
      else
        fail("[circular_loop] Expected response: [:continue | :break, value]")
      end
    end
  end
end

module Curl
  def self.get(url, options = {})
    options.reverse_update(:follow_redirects => false)
    
    circular_loop(url) do |url|
      curl = Curl::Easy.http_get(url)
      headers = {}
      curl.on_header do |header|
        key, value = header.split(":", 2).map(&:strip)
        headers[key] = value
        header.size
      end
      curl.perform
      if options[:follow_redirects] && curl.response_code.to_s =~ /^3..$/
        [:continue, URI::join(url, headers["Location"]).to_s]
      else
        [:break, curl.body_str]
      end
    end
  end

  def self.download_to_file(file_url, destination, options = {})
    options.reverse_update(:show_progressbar => false)
    
    open(destination, "wb") do |fd|
      curl = Curl::Easy.new(file_url)
      pbar = nil
      curl.on_body { |data| fd.write(data) }
      curl.on_progress do |dl_total, dl_now, ul_total, ul_now|
        if options[:show_progressbar] && dl_total > 0
          pbar ||= ProgressBar.new(destination, dl_total).tap do |pbar|
            pbar.format_arguments = [:title, :percentage, :bar, :stat_for_file_transfer]
            pbar.bar_mark = "="
            pbar.bar_end_mark = ">"
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

class Object
  include Kernel
end
