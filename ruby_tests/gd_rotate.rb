#!/usr/bin/env ruby

# Time arbitrary rotations in GD.

require 'rubygems'

require 'optparse'

require 'gd2-ffij'
include GD2

# Add path to local modules
proc {
  $LOAD_PATH.unshift(File.dirname(__FILE__))
}.call()

require 'timer'
include Timer




def flip(imgfile, angles, truecolor)
  im = nil      # declare in the local scope
  tc = "-"

  time(imgfile, "Load") {im = Image.import(imgfile)}

  time imgfile, "Converting to #{truecolor ? 'true color' : 'indexed'}." do
    if truecolor
      im = im.to_true_color()
      tc += "tc-"
    else
      im = im.to_indexed_color()
    end
  end

  base = File.basename(imgfile)
  ext = File.extname(imgfile)

  angles.each do |angle|
    result = nil
    time imgfile, angle.to_s do
      result = im.rotate(angle.degrees)
      result.export("rotate-#{angle}-gd-rb#{tc}#{base}")
    end

    # Sanity check
    raise "Lost truecolor state" unless
      result.true_color? == truecolor
  end

  print_timings()
end


truecolor = false
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} <filename> <angle> ..."
  opts.on('--truecolor', "Force images to true color instead of indexed.") {
    truecolor = true
  }
end.parse!

if ARGV.size < 2
  puts "Missing arguments.  Try '--help'."
  exit 1
end

angles = ARGV[1..-1].map{|a| a.to_i}
angles.each{|a| a > 0 && a <= 360 or raise "Invalid angle argument."}
flip ARGV[0], angles, truecolor
