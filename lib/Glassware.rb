NA
NA::Atom
NA::CL
NA::CL::Output
NA::CL::Membrane
NA::CL::Vessel
NA::CL::Pipe

module NA
  
  module Atom
    
    def to_atom
      # access object properties to grab important information
    end
  
  end
  
  module CL

    def to(component)
    $next_component = component
    self
    end
    
    private
    
    def pass(*atoms)
    $next_component.add atoms
    end
    
    def process(*atoms, &process)
    atoms.collect{|i| (process || $process).call i}
    end
    
    class Component
    include CL
      
      def initialize(next_component, &process)
      $next_component = next_component
      $process = process
      end
  
      def add(*atoms)
      end  
    
    end
    
    class Membrane < Component
    
      def add(*atoms)
      atoms && pass(process(atoms))
      end
    
    end
      
    class Vessel < Component
      
      def initialize
      super
      $contents = []
      $overflow = nil
      $size = 0
      end
      
      def to_ary
      $contents
      end
      
      def add(*atoms)
      $contents.push(atoms.slice!(0, $size-$contents.size))
      $overflow && $overflow.add(atoms)
      end

      def extract(size=1)
      $contents.shift(size)
      end
      
      def drip
      extract
      end
      
      def drain
      extract($contents.size)
      end
         
      def start_scan(period=nil, res=10)
        stop_scan
        $scanner = Thread.new {
          loop {
            t = Time.now.to_f
            if !period || (lastRun-t > period)
              lastRun = t
              pass(process(drip))
            end
            sleep res
          }
        }
      end
      
      def stop_scan
        $scanner && $scanner.kill
      end
      
    end
  
    class Pipe < Vessel
      
      def initialize
      super
      $pressure = args[:pressure] || 1
      $width = args[:grouping] || 1
      end
      
      def drip
      extract($width*$pressure)
      end
      
    end

    module Output
    include Node
      
      def from_atom(*atom)
      end
      
      def add(*atoms)
      atoms && process(atoms)
      end
      
    end

  end
      
end


  
  