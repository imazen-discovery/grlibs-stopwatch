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




def shrink(imgfile, percentages, truecolor, resample)
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

  percentages.each do |p|
    percent = p.to_i
    raise "Invalid percentage: #{p}" unless percent > 0 && percent <= 100
    
    ratio = percent / 100.0
    destWidth, destHeight = [im.width, im.height].map{|d| (d*ratio).round}

    result = nil
    time imgfile, percent.to_s do
      result = im.resize(destWidth, destHeight, resample)
      result.export("#{percent}-gd-rb#{tc}#{base}")
    end

    # Sanity check
    raise "Lost truecolor state" unless
      result.true_color? == truecolor
  end

  print_timings()
end


truecolor = false
resample = false
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} <filename> <percentage> ..."
  opts.on('--truecolor', "Force images to true color instead of indexed.") {
    truecolor = true
  }
  opts.on('--resample', "Resample when resizing; implies --truecolor.") {
    truecolor = true
    resample = true
  }
end.parse!

if ARGV.size < 2
  puts "USAGE: shrink <filename> <percentage> ..."
  exit 1
end

shrink ARGV[0], ARGV[1..-1], truecolor, resample
