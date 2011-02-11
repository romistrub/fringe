require 'demo'

module ChipmunkDemos
  module PyramidStack
    class PyramidStackDemo < Demo
      def initialize
        super
        @space.iterations = 5
        @space.resize_static_hash(40.0,1000)
        @space.resize_active_hash(40.0,1000)
        @space.gravity = cpv(0,100)
        
        @boundary = Boundary.new
        @ball = Ball.new(cpv(320,480 - Ball::RADIUS))
        @boxes = []
        for i in (0...14) do
          for j in (0..i) do
            @boxes << Box.new(cpv(j*32 - i*16 + 320, i*32 - 60))
          end
        end
        @space.add_objects(@boundary, @ball, *@boxes)
        @chipmunk_objects.push(@boundary, @ball, *@boxes)
      end
    end
    
    class Box
      include CP::Object
      VERTS = [
        cpv(-15,-15),
        cpv(-15, 15),
        cpv( 15, 15),
        cpv( 15,-15)
      ]
      MASS  = 1.0
      MOMENT = CP::moment_for_poly(MASS,VERTS,CP::vzero)
      
      attr_accessor :body, :shape
      def initialize(p)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p
        @shape = CP::Shape::Poly.new(@body,VERTS,CP::vzero)
        @shape.e = 0.0;
        @shape.u = 0.8;
        init_chipmunk_object(@body,@shape)
      end
    end
    
    class Ball
      include CP::Object
      RADIUS = 15.0
      MASS   = 10.0
      MOMENT = CP::moment_for_circle(MASS,0.0,RADIUS,CP::vzero)
      
      attr_accessor :body, :shape
      def initialize(p)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p
        @shape = CP::Shape::Circle.new(@body,RADIUS,CP::vzero)
        init_chipmunk_object(@shape,@body)
      end
    end
    
    class Boundary
      include CP::Object
      ELASTICITY = FRICTION = 1.0
      VERTICES = [
        cpv(  0,  0),
        cpv(  0,480),
        cpv(640,480),
        cpv(640,  0)
      ]
      
      attr_accessor :body, :shapes
      def initialize
        @body = CP::StaticBody.new
        @shapes = VERTICES.enum_cons(2).map do |a,b|
          seg = CP::Shape::Segment.new(@body,a,b,0.0)
          seg.e = ELASTICITY
          seg.u = FRICTION
          seg
        end
        init_chipmunk_object(@body,*@shapes)
      end
    end
  end
end