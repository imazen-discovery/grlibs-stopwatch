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


MODES = {
#  'default'             => GD_DEFAULT,
  'bell'                => GD_BELL,
  'bessel'              => GD_BESSEL,
  'bilinear_fixed'      => GD_BILINEAR_FIXED,
  'bicubic'             => GD_BICUBIC,
  'bicubic_fixed'       => GD_BICUBIC_FIXED,
  'blackman'            => GD_BLACKMAN,
  'box'                 => GD_BOX,
  'bspline'             => GD_BSPLINE,
  'catmullrom'          => GD_CATMULLROM,
  'gaussian'            => GD_GAUSSIAN,
  'generalized_cubic'   => GD_GENERALIZED_CUBIC,
  'hermite'             => GD_HERMITE,
  'hamming'             => GD_HAMMING,
  'hanning'             => GD_HANNING,
  'mitchell'            => GD_MITCHELL,
  'nearest_neighbour'   => GD_NEAREST_NEIGHBOUR,
  'power'               => GD_POWER,
  'quadratic'           => GD_QUADRATIC,
  'sinc'                => GD_SINC,
  'triangle'            => GD_TRIANGLE,
  #'weighted4'           => GD_WEIGHTED4,
}



def shrink(imgfile, widths, truecolor, modeName)
  im = nil      # declare in the local scope
  tc = "-"
  mode = MODES[modeName]

  time(imgfile, "Load") {im = Image.import(imgfile)}

  # Force input object to truecolor if needed.
  if truecolor && !im.true_color?
    time imgfile, "Converting to #{truecolor ? 'true color' : 'indexed'}." do
      im = im.to_true_color()
      tc += "tc-"
    end
  end

  base = File.basename(imgfile)
  ext = File.extname(imgfile)

  im.interpolation_method = mode
  raise "Unable to set interpolation mode." unless 
    mode == im.interpolation_method

  widths.each do |w|
    width = w.to_i
    raise "Invalid width: #{width}" unless
      width > 0 && width % 160 == 0

    destWidth = width
    destHeight = ( (im.height * width.to_f) / im.width ).round

    result = nil
    time imgfile, width.to_s do
      result = im.resizeInterpolated(destWidth, destHeight)
    end

    ofname = "resize-gd-rb-#{width}#{tc}-#{modeName}-#{base}"
    moveOldFile(ofname)

    time imgfile, "Writing:" do
      result.export(ofname, {:quality => 100})
    end

  end

  print_timings()
end

# Rename file 'name' to something different and (probably) unique
def moveOldFile(name)
  return unless File.file?(name)

  count = 0
  while true
    count += 1
    nfn = "#{name}.#{count}"

    if !File.file?(nfn)
      File.rename(name, nfn)
      break
    end
  end
end



def main
  truecolor = false
  mode = 'bicubic'

  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} <filename> <width> ..."
    opts.on('--force-truecolor', "Force input images to truecolor.") {
      truecolor = true
    }

    opts.on('--interp MODE', "Use interpolation mode 'MODE'.") { |im|
      raise "Unknown interpolation mode '#{im}'" unless MODES.has_key?(im)
      mode = im
    }

    opts.on('--modes', "List all interpolation modes and exit.") {
      print "Interpolation modes:\n\t", MODES.keys.sort.join("\n\t"), "\n"
      exit 0
    }
  end.parse!

  if ARGV.size < 2
    puts "USAGE: resize <filename> <width> ..."
    exit 1
  end

  shrink ARGV[0], ARGV[1..-1], truecolor, mode
end


main()

