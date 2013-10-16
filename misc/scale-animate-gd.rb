#!/bin/env ruby

require 'gd2-ffij'
include GD2


def shrink(imgfile, width, output)
  im = Image.import(imgfile)
  im = im.to_true_color()
  im.interpolation_method = GD_BICUBIC;

  destWidth = width
  destHeight = ( (im.height * width.to_f) / im.width ).round
  result = im.resizeInterpolated(destWidth, destHeight)

  result.export(output)
end



ffiles = []
frame = 0
for x in (16..600).step 8
  ff = "frame-#{frame}.png"
  ffiles.push ff
  puts ff

  shrink('clamptest.png', x, 'tmp.png')
  `convert -scale 600x600 tmp.png #{ff}`
  frame += 1
end
  
puts "converting..."
`convert -delay 10 #{ffiles.join(' ')} gd-scale.gif`

