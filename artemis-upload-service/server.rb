#!/usr/bin/env ruby
# frozen_string_literal: true
# Artemis' Upload Service
# This is a web service that lets you upload files and images easily
# Environment variables you need to set:
# AUTH_TOKEN=<token>
# HOST_PREFIX=https://somedomain.com/files
#
# In upload requests, set header Auth to ENV['AUTH_TOKEN'] for authentication.
#
# The server wont start if you dont provide an AUTH_TOKEN of at least length 16
#
# post to /mk/file[?name=<filename>] with a file as a body
# if you supply only an extension it'll just generate a random one for you.
# if you dont supply any filename, it'll just generate a random name with
# no extension.
#   response json:
#     {
#       "url" => "<url>"
#     }
# 
require 'sinatra'
require 'json'
require 'fileutils'

set :bind, '0.0.0.0'

# Ensure some basic auth sanity
if !ENV['AUTH_TOKEN'] or ENV['AUTH_TOKEN'].length < 16 or !ENV['HOST_PREFIX']
  puts "Set the AUTH_TOKEN environment variable to a string of length >= 16"
  puts "Set the HOST_PREFIX environment variable to the path files are hosted at" 
  exit 1
end

# Make the folder to put stuff in
FileUtils.mkdir_p 'public/files'

# Authentication for uploads
before '/mk/*' do
  halt 403 unless request.env['HTTP_AUTH'] == ENV['AUTH_TOKEN']
  content_type 'application/json'
end

# Fairly visually unambigous alphabet
ALPHABET = "abcdefghjkmnprsuvwxyz0123456789".each_char.to_a

# Generate a random alphanumeric string for filenames
def gen_rand_name
  12.times.map { ALPHABET.sample }.join
end

post '/mk/file' do
  filename = if params['name']
    if params['name'].match?(/\A\.[^.]+\z/)
      # If the names parameter is an extension, just tack on a random prefix
      "#{gen_rand_name}#{params['name']}"
    else
      # Otherwise throw a dash in there to look nice
      "#{gen_rand_name}-#{params['name']}"
    end
  else
    gen_rand_name 
  end
  IO.copy_stream(request.body, "public/files/#{filename}")
  JSON.generate(
    url: "#{ENV['HOST_PREFIX']}/#{filename}"
  )
end
