#!/usr/bin/env ruby

# Basic exercising of the new library function.

require 'rubygems'
require 'gd2-ffij'
include GD2


im = Image.import("../data/pic1.jpg")
puts "Interpolation mode: #{im.interpolation_method}"
#puts "Pixels: #{im.image_ptr[:tpixels]}"
#im.export("copy.jpg")

#puts "Setting interpolation mode to #{GD_BOX}"  # causes segfault
#im.interpolation_method = GD_BOX
#puts "Interpolation mode: #{im.interpolation_method}"

puts "Resizing."
im2 = im.resizeInterpolated(320, 320)
im2.export("little.jpg")

