#!/usr/bin/env ruby

# Run all of the benchmarks.

$LOAD_PATH.unshift(File.dirname(__FILE__)) # Local modules
require 'runner'

include Math

# Settings:
COUNT = 10               # Number of times to run each benchmark
SLEEP = 0#10               # Max number of seconds to sleep between runs

# Directories
ROOT = Dir.pwd
TMP = ROOT + '/tmp-all-benchmarks'
OUTPUT = ROOT + '/timings.tab'
CDIR = ROOT + '/c_tests'


# Commands to run
CMDS=[
      ["c_tests/shrink %s 90 60 40 20", %w{90 60 40 20}],
      ["ruby_tests/shrink.rb %s 90 60 40 20", %w{90 60 40 20}],
      ["c_tests/stats %s", %w{min max avg deviate Total:}],
      ["c_tests/benchmark %s junk_out.tiff", %w{Total:}],
     ]


def mkimg(name, pix, noisy)
  xy = sqrt(pix).round + 1
  colours = noisy ? "" : "1"
  allnames = []

  puts "Creating '#{name}'"
  system("#{ROOT}/stats_tools/mkimg.pl #{xy} #{xy} #{name}.png #{colours}") or
    raise "Error running 'mkimg.pl': #{$?}"

  for ext in %w{jpg tiff png}   # gif doesn't work; segfaults
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

def benchmarksByCmd(images, outfh)
  puts "Running benchmarks:"
  addHeading = true

  for cmdAndFields in CMDS
    cmd, fields = cmdAndFields

#    outfh.write(sprintf(cmd, '<filename>') + "\n")
    for img in images
      thisCmd = "#{ROOT}/" + sprintf(cmd, img)
      img, ext = img.split(/\./, 2)

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
    outfh.write("Vips Benchmarks\n\n")

    benchmarksByCmd(images, outfh)
  end
end

cleantmp()

puts "Done.  Output in '#{OUTPUT}'"
