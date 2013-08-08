#!/usr/bin/env ruby

# Run all of the benchmarks.

require 'set'

$LOAD_PATH.unshift(File.dirname(__FILE__)) # Local modules
require 'runner'

include Math

# Settings:
COUNT = 10               # Number of times to run each benchmark
SLEEP = 0                # Max number of seconds to sleep between runs

# Directories
ROOT = Dir.pwd
TMP = ROOT + '/tmp-all-benchmarks'
OUTPUT = ROOT + '/timings.tab'
CDIR = ROOT + '/c_tests'


# Commands to run:
# Format: [command, fields we care about, [tags] ]
CMDS=[
      ["c_tests/vips_shrink %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips]],
      ["ruby_tests/vips_shrink.rb %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips]],
      ["python_tests/vips_shrink.py %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :vips]],
      ["perl_tests/libgd_shrink.pl %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd]],
      ["perl_tests/libgd_shrink_resample.pl %s 90 60 40 20", %w{90 60 40 20}, [:shrink, :gd]],
      ["perl_tests/libgd_flip90.pl %s", %w{90 180 270 180-inplace}, [:flip, :gd]],
      ["c_tests/stats %s", %w{min max avg deviate Total:}, [:stats, :vips]],
      ["c_tests/benchmark %s junk_out.tiff", %w{Total:}, [:misc, :vips]],
     ]


def mkimg(name, pix, noisy)
  xy = sqrt(pix).round + 1
  colours = noisy ? "" : "1"
  allnames = []

  puts "Creating '#{name}'"
  system("#{ROOT}/stats_tools/mkimg.pl #{xy} #{xy} #{name}.png #{colours}") or
    raise "Error running 'mkimg.pl': #{$?}"

  for ext in %w{jpg png}   #  %w{jpg tiff png gif}
    fullname = "#{name}.#{ext}"
    allnames.push fullname
    
    next if ext == 'png'
    system("convert #{name}.png #{fullname}") or
      raise "Error running 'convert': #{$?}"
  end

  return allnames
end

def mkAllImages
  sizes = [100, 1000, 10000, 100000, 1000000, 3000000]
  names = []

  for sz in sizes
    names += mkimg("#{sz}", sz, 1)
    names += mkimg("#{sz}simple", sz, 0)
  end

  return names
end

def benchmarksByCmd(images, outfh, tags)
  tagSet = tags.to_set

  puts "Running benchmarks:"
  addHeading = true

  for cmdInfo in CMDS
    cmd, fields, cmdTags = cmdInfo

    next unless tagSet.size == 0 || (tagSet & cmdTags).size > 0

#    outfh.write(sprintf(cmd, '<filename>') + "\n")
    for img in images
      thisCmd = "#{ROOT}/" + sprintf(cmd, img)
      img, ext = img.split(/\./, 2)

      # The perl GD benchmark can't handle TIFF.  (The lib can but the
      # Perl module can't.)
      next if ext == 'tiff' && thisCmd =~ /\.pl/;

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

cleantmp()

puts "Done.  Output in '#{OUTPUT}'"
