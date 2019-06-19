#!/usr/bin/env ruby
# frozen_string_literal: true
# Artemis' Upload Service
# This is a web service that lets you upload files and images easily
#
# Environment variables:
#
# [REQUIRED]  AUTH_TOKEN=<token>
#
# [REQUIRED]  HOST_PREFIX=https://somedomain.com
#               This is wherever files will be served from
#
# [OPTIONAL]  UPLOAD_PATH=where/to/put/uploaded/files
#               default: public/files
#
# [OPTIONAL]  PORT=4567
#               Port this service will use
#               default: 4567
#
# [OPTIONAL]  HOST=127.0.0.1
#               Host this service will bind to. Set to 0.0.0.0 for all
#               interfaces
#               default: 127.0.0.1
#
# [OPTIONAL]  SERVE_FILES=TRUE
#               Whether this service should serve static files or not. Set
#               to false if that'll be handled by nginx or something.
#               default: TRUE
#
# The server wont start if you dont provide an AUTH_TOKEN of at least length 16
#
# example: AUTH_TOKEN=aaaabbbbccccdddd HOST_PREFIX='http://127.0.0.1:4567' UPLOAD_PATH=public/files PORT=4567 ruby artemis-upload-service.rb
#
# POST to /mk/file[?name=<filename>] with a file as the request body
#
#   Set the Auth header to AUTH_TOKEN
#
#   If `name` is a file extension, the server will generate a random name with
#   the provided extension
#
#   If `name` is a full file name, the server will generate a random prefix
#   and prepend it to the provided name
#
#   If `name` is not supplied, the server will generate a random name with no
#   extension
#
#   Response: the URL of the uploaded file
#
#
# POST to /mk/mirror?src=<url>
#   
#   Set the Auth header to AUTH_TOKEN
#
#   The server will download the requested URL and return a link to the
#   downloaded file
#
#   Response: the URL of the downloaded file

require 'sinatra'
require 'fileutils'
require 'http'
require 'uri'


# Fairly visually unambigous alphabet for filename generation
ALPHABET = 'abcdefghjknprsuvwxyz23467'.each_char.to_a

UPLOAD_PATH = ENV['UPLOAD_PATH'] || 'public/files/'

SERVE_FILES = if ENV['SERVE_FILES']
    ENV['SERVE_FILES'].match?(/\ATRUE\z/i)
else
    true
end

set :bind, ENV['HOST'] || '127.0.0.1'


set :static, SERVE_FILES
set :public_folder, UPLOAD_PATH

# Ensure some basic auth sanity
if !ENV['AUTH_TOKEN'] || ENV['AUTH_TOKEN'].length < 16 || !ENV['HOST_PREFIX']
  puts 'Set the AUTH_TOKEN environment variable to a string of length >= 16'
  puts 'Set the HOST_PREFIX environment variable to the path files are hosted at' 
  puts ''
  puts "Example: AUTH_TOKEN=aaaabbbbccccdddd HOST_PREFIX='http://127.0.0.1:4567' UPLOAD_PATH=public/files PORT=4567 HOST=0.0.0.0 ruby artemis-upload-service.rb"
  exit 1
end

# Make the folder to put stuff in
FileUtils.mkdir_p UPLOAD_PATH

# Authentication for uploads
before '/mk/*' do
  halt 403 unless request.env['HTTP_AUTH'] == ENV['AUTH_TOKEN']
  content_type 'text/plain; charset=utf-8'
end


# Generate a random alphanumeric string for filenames
def gen_rand_name(suffix)
  name = 6.times.map { ALPHABET.sample }.join + (suffix || "")
  if File.exists?("#{UPLOAD_PATH}/#{name}")
    gen_rand_name
  else
    name
  end
end

def gen_name(param_name)
  if param_name
    if param_name.match?(/\A\.[^.]+\z/)
      # If the names parameter is an extension, just tack on a random prefix
      gen_rand_name(param_name)
    else
      # Otherwise throw a dash in there to look nice
      gen_rand_name("-" + param_name)
    end
  else
    gen_rand_name 
  end
end

post '/mk/file' do
  name = gen_name(params['name'])
  IO.copy_stream(request.body, "#{UPLOAD_PATH}/#{name}")
  "#{ENV['HOST_PREFIX']}/#{name}\n"
end

post '/mk/mirror' do
  src = params['src']
  uri = URI.parse(URI.escape(src))
  name = gen_name(File.basename(uri.path))
  res = HTTP.follow.get(uri)
  if res.code != 200
    return "Error - Got response code #{res.code}\n"
  end
  File.open("#{UPLOAD_PATH}/#{name}", "w") do |f|
    res.body.each do |chunk|
      f.write(chunk)
    end
  end
  "#{ENV['HOST_PREFIX']}/#{name}\n"
end

# TODO /mk/yt youtube-dl frontend 
