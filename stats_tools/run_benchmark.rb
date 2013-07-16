#!/usr/bin/env ruby

# Run a benchmark repeatedly and average the times, outputing them as
# a tab-delimited text file.

require 'optparse'

$LOAD_PATH.unshift(File.dirname(__FILE__))  # Local modules
require 'runner'

$options = {
  :count        => 5,
  :sleep        => 0,
  :out          => 'benchmark_out.tab',
  :leaders      => [],
  :fields       => [],
}  

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} 'command' [fields] [--count c] [--sleep s]"

  opts.on('--count C', Float, "Number of times to run each benchmark") {|c|
    $options[:count] = c.to_i
  }

  opts.on('--sleep S', Float, "Max num seconds to sleep between runs") {|s|
    $options[:sleep] = s.to_i
  }

  opts.on('--output S', String, "Name of output file.") {|f|
    $options[:out] = f
  }

  opts.on('--leader S', String, "Preamble(s).") {|f|
    $options[:leaders].push f
  }

  opts.on('--fields S', String, "Fields retrieved (separated by comma).") {|f|
    $options[:fields] = (Set.new($options[:fields]) + f.split(/,/)).to_a
  }
end.parse!

# Actually run the thing!
begin
  cmd = ARGV.join(" ")
  raise "No command given!" if cmd == ""

  r = Runner.new(cmd, $options[:count], $options[:sleep], $options[:out],
                 $options[:leaders], $options[:fields])
  r.go()
rescue RuntimeError => e
  print "Exception: #{e}\n"
end
