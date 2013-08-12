
require 'set'

# Class which runs a benchmark and outputs the stats.
class Runner
  def initialize(cmd, count, sleep, out, leaders, fields, addHeading)
    @cmd = cmd
    @count = count
    @sleep = sleep
    @out = out          # Fixed later if not a filehandle
    @closeOut = false
    @leaders = leaders
    @fields = fields
    @addHeading = !!addHeading

    @times = []

    # Allow 'out' to be a string or a filehandle.
    if @out.class != File
      @out = File.open(@out, "w")
      raise "Unable to open file #{@out} for writing." unless @out
      @closeOut = true
    end
  end

  def go
    run()
    write()
    done()
  end

  def run()
    for n in 1 .. @count
      print "\tRun #{n}: "
      @times.push(run_once())

      if @sleep > 0
        zzz = rand(@sleep) + 1
        print "\tSleeping #{zzz} seconds."
        sleep(zzz)
      end
    end
  end

  def write()
    results = make_result_set()
    results.each {|row| @out.write(row.join("\t") + "\n")}
  end

  def done()
    @out.close() if @closeOut
  end

  private

  def run_once
    lines = IO.popen(@cmd, "r") do |pipe| 
      t = pipe.readlines().
        map{|l| l.chomp}.
        select {|l| !l.match(/^#/)}
    end

    raise "Command '#{@cmd}' failed:\n#{$?}" if $? != 0;

    fields = parse_lines(lines)
    return fields
  end

  def parse_lines(lines)
    result = {}
    for l in lines
      fname, desc, time = l.split(/\t/)
      result[desc] = time.to_f
    end
    return result
  end

  def make_result_set
    results = []

    fields = all_fields(@times)
    fieldVals = values_for_fields(fields, @times)

    results.push(@leaders.clone.map!{|a| ''} + ['Category', 'Mean Time(ms)',
                                                'Median Time', 'Min Time',
                                                'Max Time', 'Range']
                 ) if @addHeading
    @addHeading = false

    for f in fields
      fv = fieldVals[f]

      row = @leaders.clone
      row += [f, fv.mean, fv.median, fv.min, fv.max, fv.max - fv.min]

      results.push row
    end

    return results
  end

  def values_for_fields(fields, times)
    result = {}
    for f in fields
      result[f] = times.map{|r| r[f] || -1}
    end
    return result
  end

  def all_fields(times)
    fields = Set.new(@fields)
    times.each {|entry| fields += entry.keys} unless fields.size > 0
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
