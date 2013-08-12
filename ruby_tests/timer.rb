
module Timer
  @@times = []

  def time(file, desc)
    start = Time.now
    yield
    elapsed = Time.now - start
    @@times.push [elapsed.to_f, file, desc]
  end

  def print_timings
    total = 0
    @@times.each do |e|
      elapsed, file, desc = e
      print_time file, desc, elapsed * 1000
      total += elapsed
    end
    print_time "", "Total:", total*1000
  end

  def reset
    @@times = []
  end

  def print_time(file, desc, elapsed)
    print file, "\t", desc, "\t", '%.3f' % elapsed, "\n"
  end
end
