#!/usr/bin/env ruby

# Basic exercising of the new library function.

#require 'rubygems'

require 'gd2-ffij'
include GD2

im = Image::TrueColor.new(300, 300)

im.interpolation_method = GD_BICUBIC
im.resizeInterpolated(300, 600)

im.export("result.png")


