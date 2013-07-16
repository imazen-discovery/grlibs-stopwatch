#!/usr/bin/env ruby

# Simple utility to read in a file of tab-delimited data (plus a
# preamble) and reorder them so that all rows with equal values in the
# given columns are grouped together.

require 'optparse'

$count = 0
$fields = []
$blank = false

OptionParser.new do |opts|
  opts.banner =
    "Usage: #{__FILE__} [--preamble <num>] [--fields <index>(,<index>)*]\n" +
    "            [--blank] input output"

  opts.on('--preamble N', Float, "Number of leading lines to skip.") {|n| 
    $count = n.round
  }

  opts.on('--fields F', String, "List of fields (from 1, comma-separated)") {|f|
    $fields = f.split(/,/).map{|e| e.to_i - 1}
  }

  opts.on('--blank', "Leave a blank line between groups.") {
    $blank = true
  }

end.parse!

abort("No fields given.") unless $fields.size > 0
abort("Need to specify input and output.") unless ARGV.size >= 2

def key(row)
  return $fields.map{|i| row[i]}.join("\t")
end

def go(input, output)
  groups = {}
  
  lines = File.open(input, "r") { |fh| fh.readlines() }
  preamble = lines.shift($count)

  rows = lines.map!{|l| l.chomp!.split(/\t/) }

  rows.each do |row|
    k = key(row)
    groups[k] = [] unless groups.has_key?(k)
    groups[k].push row
  end

  results = []
  groups.keys.sort().each do |key|
    groups[key].each {|row| results.push row.join("\t")}
    results.push "" if $blank
  end

  File.open(output, "w") { |fh|
    fh.write(preamble.join(""))
    fh.write(results.join("\n"))
  }
end

go(*ARGV)

