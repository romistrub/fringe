module RS
  class TimedLooper < Thread
    def initialize(period = 0, resolution = 0, &p)
      @period = period
      @resolution = resolution
      
      super &Proc.new{
        last_run = Time.now.to_f
        loop {
          time = Time.now.to_f
          if (time-last_run > @period)
           last_run = time
           p.call
          end
          sleep resolution
        }
      }
    end
  end
end