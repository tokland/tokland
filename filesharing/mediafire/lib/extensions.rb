require 'curl'
require 'nestegg'
require 'progressbar'

module Enumerable
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

class String
  def split_at(idx)
    [self[0...idx] || "", self[idx..-1] || ""] 
  end
end

class MaybeWrapper
  instance_methods.each { |m| undef_method m unless m == :object_id || m =~ /^__/ }

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
  def present?
    !empty?
  end
end

class Hash
  def present?
    !empty?
  end
end

class String
  def present?
    !strip.empty?
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

class Array
  def extract_options
    if last.is_a?(Hash)
      [[0...-1], last]
    else
      [self, {}]
    end      
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
  def catch_exceptions(exit_codes)
    yield
  rescue => exc
    $stderr.puts("ERROR: #{[exc.class.name, exc.to_s].uniq.join(' - ')}")
    exit_codes.map_detect do |symbol_or_exc_class, exc_code| 
      exc_code if symbol_or_exc_class.is_a?(Class) && exc.is_a?(symbol_or_exc_class)
    end or raise
  end
  
  # contents = wrap { File.read("/etc/service") }.with({
  #   Errno::ENOENT => MyFileNotFound.new("file not found")
  #   Errno::EISDIR => MyIsADirectory.new("it's a directory")
  # })
  def wrap(&block)
    WrapClass.new(block) do
      def with(exceptions)
        begin
          block.call
        rescue *exceptions.keys => exc
          raise(*exceptions.map_detect { |from, to| to if exc.is_a?(from) } )
        end
      end
    end
  end

  def wrap_exceptions(relations)
    begin
      yield
    rescue => exc
      raise(*relations.map_detect do |source, dest|
        if exc.is_a?(source)
          dest.new([exc.class.name, exc.to_s].uniq.join(' - '))
        end
      end)
    end
  end
end

module Curl
  def self.get_with_headers(url)
    curl = Curl::Easy.http_get(url)
    headers = {}
    curl.on_header do |header|
      key, value = header.split(":", 2).map(&:strip)
      headers[key] = value
      header.size
    end
    curl.perform
    [curl.body_str, headers]
  end

  def self.download_with_progressbar(file_url, destination)
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

class Object
  include Kernel
end
