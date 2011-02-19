module Atom
  def to_atom
    # access object properties to grab important information
  end
  def from_atom(atom)
    # 
  end
end

module Interface
  def decode(atom)
    
  end
  def add(*atoms)
    atoms.collect{|i| decode i}
  end
end

# Pipe builds on ideas from MIDIator::Timer
module Glassware
  
  # A pipe is completely agnostic to the content of the $queue
  class Pipe
    
    def initialize(args, &router)
      $queue = []
      $pressure = args[:pressure] || 1
      $width = args[:grouping] || 1
      $size = args[:length] || 0
      $overflow = args[:overflow] || nil
      $router = router
    end
    
    def add(*atoms)
      $queue.push(atoms.slice!(0, $size-$queue.size))
      $overflow && $overflow.add(atoms)
      
    end
    
    ## MANUAL PULL METHODS GRAB ATOMS
    
    # draws a specific number of atoms from the pipe, according to the pressure applied
    def leak(pressure=$pressure)
      $queue.shift(pressure)
    end
    
    # pressure determines frequency of drips
    def drip
      $queue.shift($width)
    end
    
    # flow
    def flow
      $queue.shift($pressure*$width)
    end
    
    
    
    def drain
    end
    
    # can route arbitrary atoms -- could be its own class, like "reaction"
    def route(*atoms)
      atoms.each {|atom|
        $router.call(atom).add(atom)
      }
    end
    
    def join
    end
    
    def open(w=1, period=nil, res=10)  # can be used as a drip or an open valve
      close
      $scanner = Thread.new {
        loop {
          t = Time.now.to_f
          if !period || (lastRun-t > period)
            lastRun = t
            self.flow
          end
          sleep res
        }
      }
    end
    
    def close
      $scanner && $scanner.kill
    end
  
  end
  
  class Vessel
  end
  
  class Hopper < Vessel
    def initialize
      super
      
    end
  end
end