require 'json'
require 'midiator'

DEBUG = true

module NA
  
  module Atom
    def to_atom
    self
    end
  end
  
  module CL
    
    @@threads = {}
    def self.threads
      @@threads
    end

    def to(component)
    @next_component = component
    self
    end
    
    private
    
    def pass(atoms)
    puts "----"+self.class.inspect + " pass " + atoms.inspect if DEBUG
    @next_component.add atoms
    end
    
    # processes atoms [A B C] into atoms [p(A) p(B) p(C)]
    # flattens [[p(A) u(A)] [p(B) u(B)] [p(C) u(C)]] into [p(A) u(A) p(B) u(B) p(C) u(C)]
    def process(atoms, &p)
    puts "----"+self.class.inspect + " process " + atoms.inspect if DEBUG
    atoms.collect{|atom| (p || @processor).call(atom)}.flatten(1)
    end
    
    class Component
    include CL
      
      def initialize(args={}, &processor)
      @processor = processor || Proc.new {|atom| atom}
      @args = args
      end
  
      def add(atoms)
      end  
    
    end
    
    class Membrane < Component
      def add(atoms)
      atoms && pass(process(atoms))
      end 
    end
      
    class Input < Membrane 
      def add(*objs)
      super objs.collect {|obj| obj.to_atom}
      end  
    end
    
    class Vessel < Component
      
      def initialize(args={}, &processor)
      super
      @contents = []
      @overflow = @args[:overflow] || nil
      @size = @args[:size] || nil
        start_scan (@args[:period])
      end
      
      def to_ary
      @contents
      end
      
      def add(atoms)
      @contents.concat(atoms.slice!(0, @size ? @size-$contents.size : atoms.size))
      @overflow && @overflow.add(atoms)
      end

      def extract(size=1)
      @contents.shift(size)
      end
      
      def drip
      extract
      end
      
      def drain
      extract(@contents.size)
      end
         
      def start_scan(period=nil, res=0.01)
        stop_scan 
        l = Time.now.to_f
        i=0
        @thread_id = l
        @@threads[l] = Thread.new {
          loop {
            t = Time.now.to_f
            if !period || (t-l > period)
              l = t
              pass(process(drip)) unless @contents.empty?
            end
            sleep res
          }
        }
      end
      
      def stop_scan
        @thread_id && @@threads[@thread_id].kill
      end
      
    end
  
    class Pipe < Vessel
      
      def initialize
      super
      @pressure = args[:pressure] || 1
      @width = args[:grouping] || 1
      end
      
      def drip
      extract(@width*@pressure)
      end
      
    end

    module Output
    include CL
      
      def from_atom(atom)
      end
    
      def process(atoms, &p)
      puts "----"+self.class.inspect + " process " + atoms.inspect if DEBUG
      atoms.collect{|i| from_atom i}
      end
            
      def add(atoms)
      atoms && process(atoms)
      end
      
    end
    
    class Outputter
    include Output
    
      def from_atom(atom)
      puts "Output: " + atom
      end
    
    end

  end
      
end

class String
include NA::Atom
end