#!/usr/bin/env ruby


require 'rubygems'
require 'vips'

# Add path to local modules
proc {
  $LOAD_PATH.unshift(File.dirname(__FILE__))
}.call()

require 'timer'

include VIPS
include Timer

def main(imgfile, percentages)
  im = nil      # declare in the local scope
  time("Load #{imgfile}") {im = Image.new(imgfile)}

  base = File.basename(imgfile)

  percentages.each do |p|
    percent = p.to_f
    raise "Invalid percentage: #{p}" unless percent > 0 && percent <= 100
    sz = (100.0/percent).round
    time "#{imgfile}\t#{percent.to_i}" do
      im.shrink(sz).write("#{percent.round}-vips-rb-#{base}")
    end
  end

  print_timings()
end

if ARGV.size < 2
  puts "USAGE: shrink <filename> <percentage> ..."
  exit 1
end

main ARGV[0], ARGV[1..-1]
