#!/usr/bin/env ruby

# Basic exercising of the new library function.

#require 'rubygems'

require 'gd2-ffij'
include GD2

X=300
Y=300

im = Image::TrueColor.new(X, Y)

im.draw{|canvas|
  canvas.color = Color[1.0, 1.0, 1.0]
  canvas.rectangle(0, 0, X-1, Y-1, true)
}
im.export("before.png")

im.interpolation_method = GD_BICUBIC
im2 = im.resizeInterpolated(2*X, Y)
im2.export("middle.png")

im3 = im2.resizeInterpolated(X, Y)
im3.export("after.png")


