#!/usr/bin/env ruby
# This thing maps luminance values in an image to a range of colors, linearly
# interpolating between the two input colors. Check the art folder for
# example output
#
# No, we don't entirely know why we chose ruby for image processing either.
# It was mainly because we didn't want to deal with loading PNG images in C,
# or just writing C code in general. We could've used go, but meh.
#
# For a 2750x2750 image, this code might take 30-90 seconds depending on your
# CPU speed. Don't bother trying to use jruby to make it faster, jruby is
# actually about the same speed for some reason.
#
# BTW check this out https://howaboutanorange.com/blog/2011/08/10/color_interpolation/
require 'chunky_png'

# Converts sRGB 0.0-1.0 to linear 0.0-1.0
# http://www.cyril-richon.com/blog/2019/1/23/python-srgb-to-linear-linear-to-srgb
def srgb_to_linear(x)
  if x <= 0.0404482362771082
    x / 12.92
  else
    ((x + 0.055) / 1.055) ** 2.4
  end
end

def linear_to_srgb(x)
  if x > 0.0031308
    1.055 * (x ** (1.0 / 2.4) - 0.055)
  else
    12.92 * x
  end
end

def lerp(a, b, x)
  a * (1.0 - x) + b * x
end

def color_to_int_clamped(x)
  if x < 0
    0
  elsif x > 1
    1
  else
    (x * 255.0).round
  end
end

# https://en.wikipedia.org/wiki/CIE_1931_color_space
def linear_to_xyz(r, g, b)
  x = 0.49000 * r + 0.31000 * g + 0.20000 * b
  y = 0.17697 * r + 0.81240 * g + 0.01063 * b
  z = 0.00000 * r + 0.01000 * g + 0.99000 * b
  w = 1.0 / 0.17697
  [x * w, y * w, z * w]
end

def xyz_to_linear(x, y, z)
  r = 0.41847 * x - 0.15866 * y - 0.082835 * z
  g = -0.091169 * x + 0.25243 * y + 0.015708 * z
  b = 0.00092090 * x - 0.0025498 * y + 0.17860 * z
  [r, g, b]
end

def linear_to_y(r, g, b)
  y = 0.17697 * r + 0.81240 * g + 0.01063 * b
  w = 1.0 / 0.17697
  y * w
end

def linear_to_y_normalized(r, g, b)
  0.17697 * r + 0.81240 * g + 0.01063 * b
end

def hex_to_color(str)
  if str.match?(/\A#[0-9a-fA-F]{6}\z/)
    r = str[1..2].to_i(16) / 255.0
    g = str[3..4].to_i(16) / 255.0
    b = str[5..6].to_i(16) / 255.0
    [r, g, b]
  else
    [0, 0, 0]
  end
end

if ARGV.length < 4 ||
    !ARGV[0].match?(/\A#[0-9a-zA-Z]{6}\z/) ||
    !ARGV[1].match?(/\A#[0-9a-zA-Z]{6}\z/) ||
    !ARGV[2].match?(/.png\z/) ||
    !ARGV[3].match?(/.png\z/)
  puts "Usage: color-interpolate-by-luminance.rb <color0> <color1> <input.png> <output.png>"
  puts "  Ex: ./color-interpolate-by-luminance.rb #110000 #EE0000 in.png out.png"
  exit 1
end

dark = hex_to_color(ARGV[0])
light = hex_to_color(ARGV[1])

dark_xyz = linear_to_xyz(
  srgb_to_linear(dark[0]),
  srgb_to_linear(dark[1]),
  srgb_to_linear(dark[2])
)
light_xyz = linear_to_xyz(
  srgb_to_linear(light[0]),
  srgb_to_linear(light[1]),
  srgb_to_linear(light[2])
)

in_file = ARGV[2]
out_file = ARGV[3]

puts "loading image"
image = ChunkyPNG::Image.from_file(in_file)

puts "performing 2-color palettization"
image.pixels.map! do |pixel|
  pr = srgb_to_linear(ChunkyPNG::Color.r(pixel) / 255.0)
  pg = srgb_to_linear(ChunkyPNG::Color.g(pixel) / 255.0)
  pb = srgb_to_linear(ChunkyPNG::Color.b(pixel) / 255.0)
  sf = linear_to_y_normalized(pr, pg, pb)

  x = lerp(dark_xyz[0], light_xyz[0], sf)
  y = lerp(dark_xyz[1], light_xyz[1], sf)
  z = lerp(dark_xyz[2], light_xyz[2], sf)
  lrgb = xyz_to_linear(x, y, z)
  r = linear_to_srgb(lrgb[0])
  g = linear_to_srgb(lrgb[1])
  b = linear_to_srgb(lrgb[2])
  outr = color_to_int_clamped(r)
  outg = color_to_int_clamped(g)
  outb = color_to_int_clamped(b)
  ChunkyPNG::Color.rgb(outr, outg, outb)
end

puts "saving image"
image.save(out_file, :fast_rgb)
