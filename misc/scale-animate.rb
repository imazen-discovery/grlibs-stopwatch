#!/usr/bin/env ruby

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


def animate(start, stop, incr, img, useGD)
  ffiles = []
  frame = 0
  for x in (start..stop).step incr
    ff = "frame-#{'%03d' % frame}.png"
    ffiles.push ff
    puts ff
    
    if useGD
      shrink(img, x, 'tmp.png')
    else
      `convert -resize #{x}x#{x} #{img} tmp.png`
    end

    `convert -scale 600x600 tmp.png #{ff}`
    frame += 1
  end
  
  flist = ffiles.join(' ')
  puts "converting..."
  `convert -delay 10 #{flist} #{useGD ? 'gd' : 'im'}-scale.gif`

  puts "Deleting..."
  `rm #{flist}`
end


IMG = 'greenbox.png'

puts "GD version:"
animate(16, 600, 8, IMG, true)

puts "IM version:"
animate(16, 600, 8, IMG, false)
