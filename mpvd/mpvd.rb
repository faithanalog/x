#!/usr/bin/env ruby
require 'thread'

if ARGV.length == 0 || ARGV[0] == "-h" || ARGV[0] == "--help"
    puts "Usage: #{__FILE__} <queuefifo> [mpv flags]"
    exit 1
end

fifo = ARGV.shift
mpv_args = Array.new ARGV
queue = Queue.new

Thread.new do
  while true
    File.open(fifo) do |f|
      f.each_line do |ln|
        queue.push ln
      end
    end
  end
end

while true
  nxt = queue.pop
  system("mpv", *mpv_args, nxt)
end
