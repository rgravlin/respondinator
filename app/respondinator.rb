require 'bundler/setup'
require 'sinatra'
require 'thin'
require 'json'
require 'securerandom'
require 'uri'
require 'utf8-cleaner'

# Prevents UTF8 parsing errors
use UTF8Cleaner::Middleware

# Fixes Docker STDOUT logging
$stdout.sync = true

set :bind, '0.0.0.0'
set :port, 4568
set :protection, true
disable :show_exceptions, :raise_errors, :dump_errors

MAX_ROUTES = ENV['RACK_ENV'] == 'test' ? 2 : 1000
MAX_SIZE = 4096
MAX_KEYS = 3
MIN_KEYS_POST = 2
MIN_KEYS_PUT = 3

class RouteTable

  @@table ||= {}
  @@keys ||= {}
  @@ips = Hash.new { |hash, key| hash[key] = 0 }

  def self.addip(ip)
    @@ips[ip] += 1
  end

  def self.countip(ip)
    return true if @@ips[ip].to_i >= MAX_ROUTES
  end

  def self.addpath(path, response)
    @@table[path] = response
    @@table[path]
  end

  def self.getpath(path)
    @@table[path] rescue nil
  end

  def self.getpaths
    @@table.to_json
  end

  def self.hasroute(path)
    @@table.include?(path) rescue nil
  end

  def self.addkey(path)
    @@keys[path] = SecureRandom.uuid
    @@keys[path]
  end

  def self.validatekey(path,key)
    return true if @@keys[path] == key
  end

end

def valid_url?(uri)
  return false if !/^\//.match(uri)
  uri = URI.parse(uri)
rescue URI::InvalidURIError
  false
end

def errcheck(err)
  errors = {
    10 => { "error" => "Content-Length invalid" },
    20 => { "error" => "Not JSON" },
    30 => { "error" => "Invalid method for route" },
    100 => { "error" => "Route not found" },
    101 => { "error" => "Restricted route" },
    102 => { "error" => "Unacceptable route" },
    200 => { "error" => "Too many keys" },
    201 => { "error" => "Incorrect keys" },
    300 => { "error" => "Key failure" },
    500 => { "error" => "DBAG detected!" },
    501 => { "error" => "Route limit reach for IP address" }
  }

  content_type :json
  errors[err].to_json
end


before do
  # Set method
  method = request.request_method.to_s.upcase

  if ["POST","PUT"].include?(method)

    # Check header size
    halt 406, errcheck(10) if request.env["CONTENT_LENGTH"].to_i > MAX_SIZE
  
    # Validate JSON
    # TODO:
    #   - Rescue specific error types
    begin
      payload = JSON.parse(request.body.read)
    rescue JSON::ParserError => e
      halt 406, errcheck(20)
    end
  
    # Respond with pre-processing validation errors
    halt 406, errcheck(200) if payload.count > MAX_KEYS
  
    case method 
    when "POST"
      halt 401, errcheck(501) if RouteTable.countip(request.ip)
      halt 406, errcheck(201) if (payload.keys & %w{path response}).count != MIN_KEYS_POST
    when "PUT"
      halt 406, errcheck(201) if (payload.keys & %w{path response key}).count != MIN_KEYS_PUT
    end

    @key = payload['key'].to_s if payload['key']
    @path = payload['path'].to_s
    @resp = payload['response'].is_a?(Hash) ? payload['response'].to_json : payload['response'].to_s
    @ip_address = request.ip

    case method
    when "POST"
      halt 406, errcheck(30) if RouteTable.hasroute(@path)
    when "PUT"
      (halt 403, errcheck(300) unless RouteTable.validatekey(@path,@key)) if RouteTable.hasroute(@path)
    end

    halt 406, errcheck(101) if @path == "/addme"
    halt 406, errcheck(102) unless valid_url?(@path)

  end
end

put '/addme' do
  # Add route and key
  RouteTable.addpath(@path,@resp)

  rt = { "path": @path, "response": @resp }
  rk = { "key": RouteTable.addkey(@path) }

  content_type :json
  status 200
  body rt.merge(rk).to_json
end

post '/addme' do
  # Add route and key
  RouteTable.addpath(@path,@resp)
  RouteTable.addip(@ip_address)

  rt = { "path": @path, "response": @resp }
  rk = { "key": RouteTable.addkey(@path) }

  content_type :json
  status 200
  body rt.merge(rk).to_json
end

get '/*' do
  path = ['/', params[:splat]].join

  unless RouteTable.hasroute(path)
    status 200
    body errcheck(100)
  end

  RouteTable.getpath(path)
end

post '/*' do
  body errcheck(30)
end

put '/*' do
  body errcheck(30)
end

error do
  status 406
  body errcheck(500) 
end
