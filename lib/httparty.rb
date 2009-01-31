$:.unshift(File.dirname(__FILE__))

require 'net/http'
require 'net/https'
require 'core_extensions'
require 'httparty/module_inheritable_attributes'

module HTTParty
  
  AllowedFormats = {
    'text/xml'               => :xml,
    'application/xml'        => :xml,
    'application/json'       => :json,
    'text/json'              => :json,
    'application/javascript' => :json,
    'text/javascript'        => :json,
    'text/html'              => :html
  } unless defined?(AllowedFormats)
  
  def self.included(base)
    base.extend ClassMethods
    base.send :include, HTTParty::ModuleInheritableAttributes
    base.send(:mattr_inheritable, :default_options)
    base.instance_variable_set("@default_options", {})
  end
  
  module ClassMethods
    def default_options
      @default_options
    end

    def http_proxy(addr=nil, port = nil)
      default_options[:http_proxyaddr] = addr
      default_options[:http_proxyport] = port
    end

    def base_uri(uri=nil)
      return default_options[:base_uri] unless uri
      default_options[:base_uri] = HTTParty.normalize_base_uri(uri)
    end

    def basic_auth(u, p)
      default_options[:basic_auth] = {:username => u, :password => p}
    end
    
    def default_params(h={})
      raise ArgumentError, 'Default params must be a hash' unless h.is_a?(Hash)
      default_options[:default_params] ||= {}
      default_options[:default_params].merge!(h)
    end

    def headers(h={})
      raise ArgumentError, 'Headers must be a hash' unless h.is_a?(Hash)
      default_options[:headers] ||= {}
      default_options[:headers].merge!(h)
    end

    def cookies(h={})
      raise ArgumentError, 'Cookies must be a hash' unless h.is_a?(Hash)
      default_options[:cookies] ||= CookieHash.new
      default_options[:cookies].add_cookies(h)
    end
    
    def format(f)
      raise UnsupportedFormat, "Must be one of: #{AllowedFormats.values.join(', ')}" unless AllowedFormats.value?(f)
      default_options[:format] = f
    end
    
    def get(path, options={})
      perform_request Net::HTTP::Get, path, options
    end

    def post(path, options={})
      perform_request Net::HTTP::Post, path, options
    end

    def put(path, options={})
      perform_request Net::HTTP::Put, path, options
    end

    def delete(path, options={})
      perform_request Net::HTTP::Delete, path, options
    end

    private
      def perform_request(http_method, path, options) #:nodoc:
        process_cookies(options)
        Request.new(http_method, path, default_options.dup.merge(options)).perform
      end

      def process_cookies(options) #:nodoc:
        return unless options[:cookies] || default_options[:cookies]
        options[:headers] ||= {}
        options[:headers]["cookie"] = cookies(options[:cookies] || {}).to_cookie_string

        default_options.delete(:cookies)
        options.delete(:cookies)
      end
  end

  def self.normalize_base_uri(url) #:nodoc:
    use_ssl = (url =~ /^https/) || url.include?(':443')
    ends_with_slash = url =~ /\/$/
    
    url.chop! if ends_with_slash
    url.gsub!(/^https?:\/\//i, '')
    
    "http#{'s' if use_ssl}://#{url}"
  end
  
  class Basement #:nodoc:
    include HTTParty
  end
  
  def self.get(*args)
    Basement.get(*args)
  end
  
  def self.post(*args)
    Basement.post(*args)
  end

  def self.put(*args)
    Basement.put(*args)
  end

  def self.delete(*args)
    Basement.delete(*args)
  end
end

require 'httparty/cookie_hash'
require 'httparty/exceptions'
require 'httparty/request'
require 'httparty/response'
require 'httparty/parsers'
