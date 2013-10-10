#!/usr/bin/env ruby

# Simplified version of gd_resize.rb that resizes one image.

require 'rubygems'

require 'optparse'

require 'gd2-ffij'
include GD2

# Add path to local modules
proc {
  $LOAD_PATH.unshift(File.dirname(__FILE__))
}.call()


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
#  'weighted4'           => GD_WEIGHTED4,
}

im = Image::TrueColor.new(300, 300)
im.interpolation_method = GD_BICUBIC;

im.draw { |cv|
  cv.color = Color[1.0, 1.0, 1.0]
  cv.fill
}
im.export("before.png")

after = im.resizeInterpolated(600, 600)
after = after.resizeInterpolated(300, 300)
after.export("after.png")


=begin

def shrink(imgfile, width, height, output, truecolor, modeName)
  mode = MODES[modeName]
  raise "Invalid mode '#{modeName}'." unless mode

  im = Image.import(imgfile)

  # Force input object to truecolor if needed.
  if truecolor && !im.true_color?
    im = im.to_true_color()
  end


  im.interpolation_method = mode
  raise "Unable to set interpolation mode." unless 
    mode == im.interpolation_method

  raise "Invalid dimension: #{width}x#{height}" unless
    width > 0 && height > 0
  
#  destHeight = ( (im.height * width.to_f) / im.width ).round

  result = im.resizeInterpolated(width, height)

  moveOldFile(output)

  opts = {}
  case File.extname(output).downcase.to_sym
  when :jpg, :jpeg
    opts[:quality] = 100
    
    # ... more goes here, maybe ...
  end

  result.export(output, opts)
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
  mode = 'bicubic' #GD_BILINEAR_FIXED

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
      print MODES.keys.sort.join("\n"), "\n"
      exit 0
    }
  end.parse!

  if ARGV.size != 4
    puts "USAGE: resize <input> <width> <height> <output>"
    exit 1
  end

  shrink ARGV[0], ARGV[1].to_i, ARGV[2].to_i, ARGV[3], truecolor, mode
end


main()

=end
