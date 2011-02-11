require 'demo'

module ChipmunkDemos
  module Plink
    class PlinkDemo < Demo
      def initialize
        super
        @steps = 1
        @space.iterations = 5
        @space.gravity    = cpv(0, 100)
        @space.resize_static_hash(40.0,999)
        @space.resize_active_hash(30.0,2999)

        @static_body = CP::StaticBody.new

        # Add triangles. The rubyist in me says this should be converted
        # from a for-loop to an enumeration, but I guess it really doesn't
        # matter much.
        @triangles = []
        for i in (0...9) do
          for j in (0...6) do
            stagger = (j%2)*40
            offset = cpv(i*80 + stagger,j*70+130)
            @triangles << StaticTriangle.new(@static_body,offset)
          end
        end

        # Add lots of pentagons
        @pentagons = Array.new(100) do |i|
          p = cpv(rand(640),10)
          FallingPentagon.new(p)
        end

        @space.add_objects(*@triangles)
        @space.add_objects(*@pentagons)
        @chipmunk_objects << @static_body
        @chipmunk_objects.push(*@triangles)
        @chipmunk_objects.push(*@pentagons)
      end # def initialize

      def update
        @steps.times do
          @space.step(self.dt)
          @pentagons.each do |pent|
            if (pent.body.p.y > 500 || pent.body.p.y < -120)
              pent.body.p = cpv(rand(640),20)
            end # if
          end #each
        end# do
      end # update
    end # class PlinkDemo

    class StaticTriangle
      include CP::Object
      VERTICES = [
        cpv( 15, 15),
        cpv(  0,-10),
        cpv(-15, 15)
      ]
      ELASTICITY = FRICTION = 1.0

      attr_accessor :shape
      def initialize(body,offset)
        @shape = CP::Shape::Poly.new(body,VERTICES,offset)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        init_chipmunk_object(@shape)
      end
    end #class StaticTriangle

    class FallingPentagon
      include CP::Object
      NUM_VERTS = 5
      VERTICES = Array.new(NUM_VERTS) do |i|
        angle = -2*Math::PI*i/(NUM_VERTS)
        cpv(10*Math.cos(angle), 10*Math.sin(angle))
      end
      MASS       = 1.0
      MOMENT     = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
      ELASTICITY = 0.0
      FRICTION   = 0.4

      attr_accessor :shape, :body
      def initialize(p)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p
        @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        init_chipmunk_object(@body,@shape)
      end
    end # class FallingPentagon

  end
end