
require 'set'

# Class which runs a benchmark and outputs the stats.
class Runner
  def initialize(cmd, count, sleep, out, leaders, fields, addHeading)
    @cmd = cmd                  # Command to run
    @count = count              # Number of times to run each specific command
    @sleep = sleep              # Max number of seconds to sleep between runs
    @out = out                  # Output filename or filehandle
    @closeOut = false           # Should @out be closed when done?
    @leaders = leaders          # Fields to prepend to output line
    @fields = fields            # Output lines we care about (output column 2)
    @addHeading = !!addHeading  # Flag: if given, add a row of column headings.

    @times = []

    # Allow 'out' to be a string or a filehandle.
    if @out.class != File
      @out = File.open(@out, "w")
      raise "Unable to open file #{@out} for writing." unless @out
      @closeOut = true
    end

    # count must be at least 2 (so that we can separate out the first one).
    raise "Test count must be at least 2; got #{count}" if count < 2
  end

  def go
    run()
    write()
    done()
  end

  def run()
    print @cmd, " ["
    STDOUT.flush()

    for n in 1 .. @count
      print n
      STDOUT.flush()
      @times.push(run_once())

      if @sleep > 0
        zzz = rand(@sleep) + 1

        print "(sleep #{zzz})"
        STDOUT.flush()

        sleep(zzz)
      end
    end
    puts "]"
  end

  def write()
    results = make_result_set()
    results.each {|row| @out.write(row.join("\t") + "\n")}
  end

  def done()
    @out.close() if @closeOut
  end

  private

  # Execute @cmd once and return the output as a hash of field-names to
  # times.
  def run_once
    lines = IO.popen(@cmd, "r") do |pipe| 
      t = pipe.readlines().
        map {|l| l.chomp}.
        select {|l| !l.match(/^#/)}
    end

    raise "Command '#{@cmd}' failed:\n#{$?}" if $? != 0;

    return parse_lines(lines)
  end

  # Split up the output of a run into a hash matching description
  # fields (field #2 of the output) to the time it took to run (field
  # #3).
  def parse_lines(lines)
    result = {}
    for l in lines
      fname, desc, time = l.split(/\t/)
      result[desc] = time.to_f
    end
    return result
  end

  # Crunch the results into an array of values, one per output field.
  # This will be output as a line of tab-delimited fields.
  def make_result_set
    results = []

    fieldSet = all_fields()
    fieldVals = values_for_fields(fieldSet)

    results.push(@leaders.clone.map!{|a| ''} + ['Category', 'Mean Time(ms)',
                                                'Median Time', 'Min Time',
                                                'Max Time', 'Range']
                 ) if @addHeading
    @addHeading = false

    for f in fieldSet
      fv = fieldVals[f]

      row = @leaders.clone
      row += [f, fv.mean, fv.median, fv.min, fv.max, fv.max - fv.min]

      results.push row
    end

    return results
  end

  # Return a hash mapping each field name in 'fields' to an array of
  # all of the times for that field.
  def values_for_fields(fields)
    result = {}
    for f in fields
      result[f] = @times.map{|r| r[f] or raise "Missing field: #{r}"}
    end
    return result
  end

  # Return a Set containing all of the field IDs (the items in field
  # #2 of a benchmark program's output) that we care about.  This is
  # the value of @fields unless it was empty in which case we default
  # to everything.
  def all_fields
    fields = Set.new(@fields)
    @times.each {|entry| fields += entry.keys} unless fields.size > 0
    return fields.to_a.sort
  end
end

class Array
  def sum
    reduce(0){|memo, elem| memo+elem}
  end

  def mean
    sum/(size + 0.0)
  end

  def median
    return self[0] if size <= 1
    return sort()[size()/2 - 1]
  end
end
