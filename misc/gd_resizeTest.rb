#!/usr/bin/env ruby

# Basic exercising of the new library function.

require 'rubygems'
require 'gd2-ffij'
include GD2


im = Image.import("../data/pic1.jpg")
puts "Interpolation mode: #{im.interpolation_method}"

puts "Setting interpolation mode to #{GD_BOX}"
im.interpolation_method = GD_BOX
puts "Interpolation mode: #{im.interpolation_method}"
