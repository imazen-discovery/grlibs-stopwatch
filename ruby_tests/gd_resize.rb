#!/usr/bin/env ruby

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




def shrink(imgfile, widths, truecolor, resample)
  im = nil      # declare in the local scope
  tc = "-" + (resample ? "rs-" : "")

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

  widths.each do |w|
    width = w.to_i
    raise "Invalid width: #{width}" unless
      width > 0 && width % 160 == 0
    
#    raise "Only shrinking is currently supported." if width >= im.width

    destWidth = w
    destHeight = ( (im.height * width.to_f) / im.width ).round

    result = nil
    time imgfile, width.to_s do
      result = im.resize(destWidth, destHeight, resample)
    end

    # Sanity check
    raise "Lost truecolor state" unless
      result.true_color? == truecolor
    
    ofname = "resize-gd-rb-#{width}#{tc}#{base}"

    # Warn if output file is being overwritten.
    File.file?(ofname) and puts "Overwriting '#{ofname}'!!!!"

    time imgfile, "Writing:" do
      result.export(ofname, {:quality => 100})
    end

  end

  print_timings()
end


truecolor = false
resample = false
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} <filename> <width> ..."
  opts.on('--truecolor', "Force images to true color instead of indexed.") {
    truecolor = true
  }
  opts.on('--resample', "Resample when resizing; implies --truecolor.") {
    truecolor = true
    resample = true
  }
end.parse!

if ARGV.size < 2
  puts "USAGE: shrink <filename> <width> ..."
  exit 1
end

shrink ARGV[0], ARGV[1..-1], truecolor, resample
