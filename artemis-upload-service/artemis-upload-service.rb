#!/usr/bin/env ruby
# frozen_string_literal: true
# Artemis' Upload Service
# This is a web service that lets you upload files and images easily
#
# Environment variables:
# [REQUIRED]  AUTH_TOKEN=<token>
# [REQUIRED]  HOST_PREFIX=https://somedomain.com/files
# [OPTIONAL]  UPLOAD_PATH=where/to/put/uploaded/files
#               default: public/files
# [OPTIONAL]  PORT=4567
#               default: 4567
# [OPTIONAL]  HOST=127.0.0.1
#               default: 127.0.0.1
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

require 'sinatra'
require 'fileutils'

set :bind, ENV['HOST'] || '127.0.0.1'

# Fairly visually unambigous alphabet for filename generation
ALPHABET = 'abcdefghjknprsuvwxyz23467'.each_char.to_a

UPLOAD_PATH = ENV['UPLOAD_PATH'] || 'public/files/'

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

post '/mk/file' do
  name = if params['name']
    if params['name'].match?(/\A\.[^.]+\z/)
      # If the names parameter is an extension, just tack on a random prefix
      gen_rand_name(params['name'])
    else
      # Otherwise throw a dash in there to look nice
      gen_rand_name("-" + params['name'])
    end
  else
    gen_rand_name 
  end
  IO.copy_stream(request.body, "#{UPLOAD_PATH}/#{name}")
  "#{ENV['HOST_PREFIX']}/#{name}"
end
