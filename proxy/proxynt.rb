#!/usr/bin/ruby
require 'rubygems'
require 'webrick/httpproxy'
require 'logger'
require 'open3'
require 'yaml'

module HashExtensions
  # Return a hash with all string keys symbolized (recursively)
  def symbolize_keys
    self.inject({}) do |hash, (key, value)|
       new_key = key.is_a?(String) ? key.to_sym : key
       new_value = value.is_a?(Array) ? value.map { |v| v.is_a?(Hash) ? v.symbolize_keys : v } : value
       hash.merge(new_key => new_value)
    end
  end

  # Return copy of hash remove some keys   
  def except(*keys)
    Hash[self.reject { |k, v| keys.include?(k) }]
  end
end

module HTTPRequestExtensions
  # Change URI of HTTP request
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
  #  :port - Port for HTTP Proxy server
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
    trap("INT") { @server.shutdown }
  end
    
  # Start server (blocking)
  def start
    @server.start
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
      new_body = options.except(:conditions).inject(response.body) do |body, (filter_key, filter_value)|
        case filter_key
        when :command
          Open3.popen3(filter_value) do |stdin, stdout, stderr|
            stdin.write(body)
            stdin.close
            stdout.read
          end
        else
          fail "unknown action for filter"
        end || body
      end
      
      @logger.debug("New body (#{response.content_type}): #{response.body.size} bytes")
      response.body = new_body
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
    STDERR.puts "Usage: proxynt CONFIGYAML"
    return 1
  end
  Hash.send(:include, HashExtensions)
  config = YAML::load(open(args.first).read).symbolize_keys

  proxy_interceptor = ProxyInterceptor.new(config)
  proxy_interceptor.start
end

if __FILE__ == $0
  exit(main(ARGV) || 0)
end
