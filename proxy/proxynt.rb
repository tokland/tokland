#!/usr/bin/ruby
require 'rubygems'
require 'webrick/httpproxy'
require 'logger'
require 'open3'
require 'yaml'

module HashExtensions
  # Return a hash with all string keys symbolized (act recursively on values)
  #
  # >> {"a" => [{"b" => 2}, {"c" => 3, 4000 => 4}], "e" => 5}
  # => {:a => [{:b => 2}, {:c => 3, 4000 => 4}], :e => 5}
  def symbolize_keys
    self.inject({}) do |hash, (key, value)|
      new_key = key.is_a?(String) ? key.to_sym : key
      new_value = if value.is_a?(Array) 
        value.map { |v| v.respond_to?(:symbolize_keys) ? v.symbolize_keys : v }
      else
        value
      end
      hash.merge(new_key => new_value)
    end
  end

  # Return copy of hash remove some keys
  #
  # >> {"a" => 1, "b" => 2, :c => 3}.except("a", :c, :foo)
  # => {"b" => 1}
  def except(*keys)
    Hash[self.reject { |k, v| keys.include?(k) }]
  end
end

module HTTPRequestExtensions
  # Change internal URI state for HTTP request
  def update_uri(uri)
    @unparsed_uri = uri
    @request_uri = parse_uri(uri)
  end
end

###

WEBrick::HTTPRequest.send(:include, HTTPRequestExtensions)

class ProxyInterceptor
  # Return a new ProxyInterceptor. 
  #
  # options:
  #  :port - Port value for HTTP Proxy server
  #  :log_level - Logger level (see Logger::Severity)
  #  :urlmapping - [{:from => Regexp, :to => String}, ...] 
  #  :filters - [{:conditions => {content_type => Regexp, :request_url => String}, 
  #               :command => String}, ...]
  def initialize(options = {})
    @logger = Logger.new(STDERR)
    @logger.level = options[:log_level] || Logger::DEBUG
    @logger.debug("Create ProxyInterceptor: #{options.inspect}")
    @urlmapping = options[:urlmapping] || []
    @filters = options[:filters] || []
    @server = WEBrick::HTTPProxyServer.new({
      :Port => options[:port] || 8080,
      :BindAddress => '0.0.0.0',
      :RequestCallback => self.method(:request_callback), 
      :ProxyContentHandler => self.method(:proxy_content_handler), 
    })
  end
    
  # Start server (blocking)
  def start
    @logger.debug("start server")
    @server.start
  end
  
  # Stop the server
  def stop
    @logger.debug("stop server")
    @server.shutdown
  end
  
  # Update config options :urlmapping and :filters (see initialize)
  def update_config(options = {})
    @logger.debug("config changed: #{options.inspect}")
    @urlmapping = options[:urlmapping] || []
    @filters = options[:filters] || []
  end

private
  
  def proxy_content_handler(request, response)
    @logger.debug("<- #{request.request_method} #{request.request_uri.to_s}")
    @logger.debug("Response body (#{response.content_type}): #{response.body.size} bytes")
    @filters.detect do |options|
      next unless options[:conditions].all? do |key, value|        
        case key.to_sym
        when :request_url
          request.request_uri.to_s.match(Regexp.new(value))
        when :content_type
          response.content_type.match(Regexp.new(value))
        else
          fail "unknown key for filter condition: #{key}"
        end 
      end
      
      @logger.debug("Applying filter: #{options.inspect}")
      new_body = options.except(:conditions).inject(response.body) do |body, (key, value)|
        case key
        when :command
          Open3.popen3(value) do |stdin, stdout, stderr|
            stdin.write(body)
            stdin.close
            stdout.read
          end
        when :proc
          value.call(response.body)
        else
          fail "unknown action key for filter: #{key}"
        end || body
      end
      
      @logger.debug("New body (#{response.content_type}): #{response.body.size} bytes")
      response.body = new_body
      # Some apps don't like discrepancies between body size and Content-length  
      response.header["content-length"] = new_body.size
      options
    end
  end

  def request_callback(request, response)
    @logger.debug("-> #{request.request_method} #{request.request_uri.to_s}")
    @urlmapping.detect do |options|
      if request.request_uri.to_s.match(options[:from])
        @logger.debug("url mapped: #{options[:from]} -> #{options[:to]}")
        request.update_uri(options[:to])
        options[:to]
      end
    end
  end  
end

def main(args)
  if args.empty?
    STDERR.puts "Usage: proxynt [CONFIG_YAML]"
    return 1
  end
  
  Hash.send(:include, HashExtensions)
  load_config = proc { YAML::load(open(args.first).read).symbolize_keys }
  proxy_interceptor = ProxyInterceptor.new(load_config.call)
  Kernel.trap("INT") { proxy_interceptor.stop }
  Kernel.trap("HUP") { proxy_interceptor.update_config(load_config.call) }
  proxy_interceptor.start
end

if __FILE__ == $0
  Kernel.exit(main(ARGV) || 0)
end
