#!/bin/env ruby

ffiles = []
frame = 0
for x in (16..600).step 8
  ff = "frame-#{frame}.png"
  ffiles.push ff
  puts ff
  `convert -resize #{x}x#{x} clamptest.png tmp.png`
  `convert -scale 600x600 tmp.png #{ff}`
  frame += 1
end
  
puts "converting..."
`convert -delay 10 #{ffiles.join(' ')} im-scale.gif`

