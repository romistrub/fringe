# This demo cannot function in ruby as yet, as it requires access to a body's
# velocity_func pointer, which the Ruby wrapper for chipmunk does not provide.

=begin
require 'demo'

module ChipmunkDemos
  module Planet
    class PlanetDemo < Demo
      def initialize
        super
        @steps = 1
        @planet = Planet.new(CP::vzero)
        @boxes  = Array.new(30) {Box.new()}
      end
      
      def rand_pos(radius)
        loop do
          v = cpv(rand(640 - 2*radius) - (320 - radius),
                           rand(480 - 2*radius) - (240 - radius))
          return v if v.length >= 100.0
        end
      end
      
      def update
        self.steps.times do
          @space.step(self.dt)
          
          # update the planet's spin so that it looks like its rotating.
          @planet.update_position(self.dt)
        end
      end #def update
    end # class PlanetDemo
    
    class Box
      include CP::Object
      SIZE     = 10.0
      MASS     =  1.0
      RADIUS   = cpv(size,size).length
      VERTICES = [
        cpv(-size,-size),
        cpv(-size, size),
        cpv( size, size),
        cpv( size,-size)
      ]
      MOMENT   = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
      
    
    
      attr_accessor :body, :shape
      def initialize(p)
      end
    end    
    
  end # module Planet
end # module ChipmunkDemos
=end