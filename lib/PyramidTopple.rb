require 'demo'

module ChipmunkDemos
  module PyramidTopple
    class PyramidToppleDemo < Demo
      def initialize
        super
        @space.iterations = 20
        @space.resize_active_hash(40.0,2999)
        @space.resize_static_hash(40.0,999)
        @space.gravity = cpv(0, 300)
      
        @floor = Floor.new
        @dominoes = []
        height = 9
        for i in (1..height) do
          offset = cpv(-i*60/2.0 + 320, (i - height)*52 + 240)
          for j in (0...i) do
            @dominoes << Domino.new(cpv(j*60,220) + offset)
            @dominoes << Domino.new(cpv(j*60,197) + offset,Math::PI/2.0)
            next if j == (i - 1)
            @dominoes << Domino.new(cpv(j*60 + 30,191) + offset,Math::PI/2.0)
          end
          @dominoes << Domino.new(cpv(-17,174) + offset)
          @dominoes << Domino.new(cpv((i - 1)*60 + 17, 174) + offset)
        end
      
        @space.add_objects(@floor,*@dominoes)
        @chipmunk_objects.push(@floor,*@dominoes)
      end
    end # class PyramidToppleDemo
    
    class Domino
      include CP::Object
      VERTICES = [
        cpv(-3,-20),
        cpv(-3, 20),
        cpv( 3, 20),
        cpv( 3,-20)
      ]
      MASS       = 1.0
      MOMENT     = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
      ELASTICITY = 0.0
      FRICTION   = 0.6
      
      attr_reader :body, :shape
      def initialize(p,angle=nil)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p
        @body.angle = angle if angle
        @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        
        init_chipmunk_object(@body,@shape)
      end
    end
    
    class Floor
      include CP::Object
      ELASTICITY = FRICTION = 1.0
      
      attr_reader :body, :shape
      def initialize
        @body = CP::StaticBody.new
        a = cpv(-280,480)
        b = cpv( 920,480)
        @shape = CP::Shape::Segment.new(@body,a,b,0.0)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        init_chipmunk_object(@body,@shape)
      end
    end
  end # module PyramidTopple
end # module ChipmunkDemos