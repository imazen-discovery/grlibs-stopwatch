
module Timer
  @@times = []

  def time(desc)
    start = Time.now
    yield
    elapsed = Time.now - start
    @@times.push [elapsed.to_f, desc]
  end

  def print_timings
    total = 0
    @@times.each do |e|
      elapsed, desc = e
      puts "#{desc}\t#{elapsed * 1000}"
      total += elapsed
    end
    puts "Total\t#{total*1000}"
  end

  def reset
    @@times = []
  end
end
