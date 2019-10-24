#!/usr/bin/env ruby
# frozen_string_literal: true
# Clipboard Register
# This is a web service that makes it easy to transfer text between machines
# in a way that only keeps the data around temporarily
#
# Environment variables:
#
# [REQUIRED]  AUTH_TOKEN=<token>
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
# The server wont start if you dont provide an AUTH_TOKEN of at least length 16
#
# example: AUTH_TOKEN=aaaabbbbccccdddd HOST_PREFIX='http://127.0.0.1:4567' UPLOAD_PATH=public/files PORT=4567 ruby artemis-upload-service.rb
#

require 'sinatra'

set :bind, ENV['HOST'] || '127.0.0.1'
set :static, false

# Ensure some basic auth sanity
#if !ENV['AUTH_TOKEN'] || ENV['AUTH_TOKEN'].length < 16 || !ENV['HOST_PREFIX']
  #puts 'Set the AUTH_TOKEN environment variable to a string of length >= 16'
  #puts 'Set the HOST_PREFIX environment variable to the path files are hosted at' 
  #puts ''
  #puts "Example: AUTH_TOKEN=aaaabbbbccccdddd HOST_PREFIX='http://127.0.0.1:4567' UPLOAD_PATH=public/files PORT=4567 HOST=0.0.0.0 ruby artemis-upload-service.rb"
  #exit 1
#end

# Authentication for uploads
#before '/mk/*' do
  #halt 403 unless request.env['HTTP_AUTH'] == ENV['AUTH_TOKEN']
  #content_type 'text/plain; charset=utf-8'
#end

$paste_register = ''
$paste_expire_time = Time.new

Thread.new do
  while true
    if Time.new >= $paste_expire_time
      $paste_register = ''
    end
    sleep 60
  end
end

post '/paste' do
  $paste_expire_time = Time.new + (60 * 5)
  $paste_register = request.body.read
  "pasted\n"
end

post '/clear_paste' do
  $paste_register = ''
  "cleared\n"
end

get '/paste' do
  $paste_register
end

get '/' do
  File.read 'index.html'
end
