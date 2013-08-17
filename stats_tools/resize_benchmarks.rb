#!/usr/bin/env ruby

# Run all of the benchmarks.

require 'optparse'
require 'set'

$LOAD_PATH.unshift(File.dirname(__FILE__)) # Local modules
require 'runner'

include Math

# Settings:
RUNS = 5                # Number of times to run each benchmark
SLEEP = 0                # Max number of seconds to sleep between runs

# Global flags
$minimal = false         # True -> only test on one small image; for testing

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
    cmd = "./ruby_tests/gd_resize.rb --interp #{mode} %s #{SIZES.join(' ')}"
    fields = sizes.map{|s| s.to_s}

    for img in images
      thisCmd = "#{ROOT}/" + sprintf(cmd, img)
      img, ext = img.split(/\./, 2)

      # The perl^Wruby GD benchmark can't handle TIFF.  (The lib can
      # but the Perl^WRuby module can't.)
      next if ext == 'tiff' && thisCmd =~ /gd_/;

      # VIPS can't handle GIF
      next if ext == 'gif' && thisCmd !~ /\.pl/;

      puts "\t#{thisCmd}"
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

  # Options
  keep = false

  # Parse the options
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [--keep] <tag> ..."
    opts.on('--keep',    "Do not delete temp. files.") {keep = true}
    opts.on('--minimal', "Only test for one small image.") {$minimal = true}
  end.parse!

  # Create the tmp directory
  cleantmp()   # Clear the old TMP if the last run was interrupted
  Dir.mkdir(TMP) or
    raise "Unable to create #{TMP}"

  # Do the tests from inside the tmp directory
  Dir.chdir(TMP) do |path|
    images = Dir.glob("#{DATADIR}/*.jpg").sort
    images = images.select{|f| f != 'pic1.jpg'} # The unused image
    
    File.open(OUTPUT, "w") do |outfh|
      outfh.write("Library Benchmarks\n\n")

      benchmarksByCmd(outfh, images, MODES, SIZES, RUNS)
    end
  end

  cleantmp() unless keep

  puts "Done.  Output in '#{OUTPUT}'"
end


go()
