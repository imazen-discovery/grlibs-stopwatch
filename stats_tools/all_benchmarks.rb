#!/usr/bin/env ruby

# Run all of the benchmarks.

require 'optparse'
require 'set'

$LOAD_PATH.unshift(File.dirname(__FILE__)) # Local modules
require 'runner'

include Math

# Settings:
COUNT = 10               # Number of times to run each benchmark
SLEEP = 0                # Max number of seconds to sleep between runs

# Global flags
$keep = false            # If true, keep intermediate files.

# Directories
ROOT = Dir.pwd
TMP = ROOT + '/tmp-all-benchmarks'
OUTPUT = ROOT + '/timings.tab'
CDIR = ROOT + '/c_tests'
DATADIR = ROOT + '/data'

# Commands to run:
# Format: [command, fields we care about, [tags] ]
CMDS=[
      ["c_tests/vips_shrink %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips]],
      ["ruby_tests/vips_shrink.rb %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips, :ruby]],
      ["python_tests/vips_shrink.py %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips]],
      # ["perl_tests/libgd_shrink.pl %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd]],
      # ["perl_tests/libgd_shrink_resample.pl %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd]],
      # ["perl_tests/libgd_shrink_truecolour.pl %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd]],
      ["ruby_tests/gd_shrink.rb %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd, :ruby]],
      ["ruby_tests/gd_shrink.rb --resample %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd, :ruby]],
      ["ruby_tests/gd_shrink.rb --truecolor %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd, :ruby]],
      ["perl_tests/libgd_flip90.pl %s", %w{90 180 270 180-inplace}, [:flip, :gd]],
      ["c_tests/stats %s", %w{min max avg deviate Total:}, [:stats, :vips]],
      ["c_tests/benchmark %s junk_out.tiff", %w{Total:}, [:misc, :vips]],
     ]


# Parse the options
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [--keep] <tag> ..."
  opts.on('--keep', "Do not delete temp. files.") {$keep = true}
end.parse!



def mkimg(name, pix)
  xy = sqrt(pix).round + 1
  allnames = []

  puts "Creating '#{name}'"
  system("convert #{DATADIR}/pic1.jpg -resize #{xy}x#{xy}! #{name}.jpg") or
       raise "Error running 'convert': #{$?}"

  for ext in %w{jpg tiff png gif}
    fullname = "#{name}.#{ext}"
    allnames.push fullname
    
    next if ext == 'jpg'
    system("convert #{name}.jpg #{fullname}") or
      raise "Error running 'convert': #{$?}"
  end

  return allnames
end

def mkAllImages
  sizes = [100, 1000, 10000, 100000, 1000000, 3000000]
  names = []

  for sz in sizes
    names += mkimg("#{sz}", sz)
  end

  return names
end

def benchmarksByCmd(images, outfh, tags)
  tagSet = tags.to_set

  puts "Running benchmarks:"
  addHeading = true

  for cmdInfo in CMDS
    cmd, fields, cmdTags = cmdInfo

    next unless tagSet.size == 0 || tagSet & cmdTags == tagSet

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
                  COUNT,
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



# See if any tags were specified on the arg list
tags = []
if ARGV.size > 0
  tags = ARGV.map {|s| s.to_sym}
end


# Create the tmp directory
cleantmp()   # Clear the old TMP if the last run was interrupted
Dir.mkdir(TMP) or
  raise "Unable to create #{TMP}"


# Rebuild the C benchmarks
Dir.chdir(CDIR) do |path|
  system("make clean") && system("make") or
    raise "Error rebuilding C benchmarks."
end

# Do the tests from inside the tmp directory
Dir.chdir(TMP) do |path|
  images = mkAllImages()

  File.open(OUTPUT, "w") do |outfh|
    outfh.write("Library Benchmarks\n\n")

    benchmarksByCmd(images, outfh, tags)
  end
end

cleantmp() unless $keep

puts "Done.  Output in '#{OUTPUT}'"
