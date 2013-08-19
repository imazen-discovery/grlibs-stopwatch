#!/usr/bin/env ruby

# Run all of the benchmarks.

require 'optparse'
require 'set'

$LOAD_PATH.unshift(File.dirname(__FILE__)) # Local modules
require 'runner'

include Math

# Settings:
RUNS  = 5                # Number of times to run each benchmark
SLEEP = 0                # Max number of seconds to sleep between runs

# Directories
ROOT = Dir.pwd
TMP = ROOT + '/tmp-all-benchmarks'
OUTPUT = ROOT + '/resize_timings.tab'
DATADIR = ROOT + '/data'

# Modes and widths
MODES = %w{bicubic_fixed bilinear_fixed nearest_neighbour} # weighted4}
SIZES = [160, 320, 480, 640, 800, 1280, 1600, 2080]



def benchmarksByCmd(outfh, images, modes, sizes, runs)
  puts "Running benchmarks:"
  addHeading = true

  for mode in modes
    cmd = "ruby_tests/gd_resize.rb --interp #{mode} %s #{sizes.join(' ')}"
    fields = sizes.map{|s| s.to_s}

    for img in images
      thisCmd = "#{ROOT}/" + sprintf(cmd, img)
      img, ext = img.split(/\./, 2)

      # The perl^Wruby GD benchmark can't handle TIFF.  (The lib can
      # but the Perl^WRuby module can't.)
      next if ext == 'tiff' && thisCmd =~ /gd_/;

      # VIPS can't handle GIF
      next if ext == 'gif' && thisCmd !~ /\.pl/;

      Runner.new( thisCmd,
                  runs,
                  SLEEP,
                  outfh, 
                  ['', sprintf(cmd, '<fn>'), img, ext],
                  fields,
                  addHeading
                  ).go()
      addHeading = false
    end
  end
end

def cleantmp
  return unless File.exist?(TMP)
  raise "#{TMP} exists but is not a directory!" unless
    File.ftype(TMP) == "directory"

  Dir.chdir(TMP) do |path|
    puts "Deleting all temp files..."
    Dir.foreach('.') do |filename|
      next if File.ftype(filename) != "file"
      puts "Unlinking #{filename}"
      File.unlink(filename)
    end
  end

  puts "Unlinking #{TMP}"
  Dir.unlink(TMP)
end



def go

  # Parameters
  sizes = SIZES
  runs = RUNS
  maximages = -1    # As many as are present

  # Options
  keep = false
  modes = []

  # Parse the options
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [FLAGS] <image> ..."
    opts.on('--keep',    "Do not delete temp. files.") {keep = true}

    opts.on('--minimal', "Only test for one small image.") {
      sizes = sizes[0..2]
      runs = 1
      maximages = 1
    }

    opts.on('--mode MODE', "Use interpolation mode MODE.") {|m|
      raise "Unknown mode: #{m}" unless MODES.include?(m)
      modes.push m
    }

    opts.on('--max-images N', OptionParser::DecimalInteger, 
            "Only process the first N images.") {|n|
      maximages = n
    }

    opts.on('--runs N', OptionParser::DecimalInteger, 
            "Run each test N times.") {|n|
      runs = n
    }

  end.parse!

  # If no modes given, do them all.
  modes = MODES unless modes.size > 0

  # Get the images to process.
  images = ARGV
  if images.size == 0
    images = Dir.glob("#{DATADIR}/*.jpg").sort
    images = images.select{|f| f != 'pic1.jpg'} # The unused image
  end
  images = images[0..(maximages - 1)] if maximages > 0
  images.map!{|f| File.expand_path(f)}    # So we can chdir()

  # Create the tmp directory
  cleantmp()   # Clear the old TMP if the last run was interrupted
  Dir.mkdir(TMP) or
    raise "Unable to create #{TMP}"

  # Do the tests from inside the tmp directory
  Dir.chdir(TMP) do |path|
    File.open(OUTPUT, "w") do |outfh|
      outfh.write("Library Benchmarks\n\n")

      benchmarksByCmd(outfh, images, modes, sizes, runs)
    end
  end

  cleantmp() unless keep

  puts "Done.  Output in '#{OUTPUT}'"
end


go()
