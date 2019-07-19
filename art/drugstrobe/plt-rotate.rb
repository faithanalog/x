#!/usr/bin/env ruby
require 'chunky_png'

def linear_to_y_normalized(r, g, b)
  0.17697 * r + 0.81240 * g + 0.01063 * b
end

def srgb_to_linear(x)
  if x <= 0.0404482362771082
    x / 12.92
  else
    ((x + 0.055) / 1.055) ** 2.4
  end
end

def srgb_to_grey_notlinear(r, g, b)
  (r + g + b) / 3
end

if ARGV.length < 3
  puts "Usage: #{__FILE__} palette-file.png image.png output.png|outputfolder [rotation-start] [rotation-end]"
  exit 1
end

palette_file = ARGV[0]
image_file = ARGV[1]
output_file = ARGV[2]
rotation_start = (ARGV[3] || "0").to_i
rotation_end = (ARGV[4] || rotation_start).to_i

palette_img = ChunkyPNG::Image.from_file(palette_file)
image_img = ChunkyPNG::Image.from_file(image_file)

$palette = palette_img.pixels
$in_pixels = Array.new(image_img.pixels)

def palettize(rotation)
  $in_pixels.map do |pixel|
    y = srgb_to_grey_notlinear(
          ChunkyPNG::Color.r(pixel) / 255.0,
          ChunkyPNG::Color.g(pixel) / 255.0,
          ChunkyPNG::Color.b(pixel) / 255.0)
    #y = linear_to_y_normalized(
          #srgb_to_linear(ChunkyPNG::Color.r(pixel) / 255.0),
          #srgb_to_linear(ChunkyPNG::Color.g(pixel) / 255.0),
          #srgb_to_linear(ChunkyPNG::Color.b(pixel) / 255.0))
    #y = 0 if y < 0
    #y = 1 if y > 1
    idx = ((($palette.length - 1) * y).to_i + rotation) % $palette.length
    $palette[idx]
  end
end

puts "palettizing"

if rotation_start == rotation_end
  image_img.pixels.replace(palettize(rotation_start))
  puts "saving image"
  image_img.save(output_file, :fast_rgb)
else
  num_frames = (rotation_end - rotation_start) + 1
  num_digits = num_frames.to_s.length
  fmt = "%0#{num_digits}d"
  frame = 0
  (rotation_start .. rotation_end).each do |rotation|
    frame_s = fmt % frame
    puts "frame #{frame_s}"
    image_img.pixels.replace(palettize(rotation))
    image_img.save("#{output_file}/#{frame_s}.png", :fast_rgb)

    frame = frame + 1
  end
end
