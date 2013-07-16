#!/usr/bin/env ruby

# Simple utility to read in a file of tab-delimited data (plus a
# preamble) and sort it by the named columns in order of priority.

require 'optparse'

$count = 0
$fields = []

OptionParser.new do |opts|
  opts.banner =
    "Usage: #{__FILE__} [--preamble <num>] [--fields <index>(,<index>)*]\n" +
    "            input output"

  opts.on('--preamble N', Float, "Number of leading lines to skip.") {|n| 
    $count = n.round
  }

  opts.on('--fields F', String, "List of fields (from 1, comma-separated)") {|f|
    $fields = f.split(/,/).map{|e| e.to_i - 1}
  }
end.parse!

abort("No fields given.") unless $fields.size > 0
abort("Need to specify input and output.") unless ARGV.size >= 2


def fldcmp(a, b)
  $fields.each{|i| return a[i] <=> b[i] unless a[i] == b[i]}
  return 0
end

def go(input, output)

  lines = File.open(input, "r") { |fh| fh.readlines() }
  preamble = lines.shift($count)

  rows = lines.map!{|l| l.chomp!.split(/\t/) }
  rows.sort! {|a, b| fldcmp(a, b) }
  lines = rows.map{|l| l.join("\t") + "\n"}

  File.open(output, "w") { |fh|
    fh.write(preamble.join(""))
    fh.write(lines.join(""))
  }
end

go(*ARGV)

