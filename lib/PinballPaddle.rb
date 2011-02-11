require 'demo'

module ChipmunkDemos
  module PinballPaddle
    class PinballPaddleDemo < Demo
      OPTIONS = {
        :title => "Paddle Demo"
      }
      def initialize
        super
        @steps = 2
        @space.gravity = cpv(0,200)
        @frame  = Frame.new
        @paddle = PaddleAssembly.new(cpv(320,240),@frame.body)
        
        @space.add_objects(@frame,@paddle)
        @chipmunk_objects.push(@frame,@paddle)
      end
      def update
        @paddle.paddle.body.reset_forces
        if self.arrow_direction.x == 1
          @paddle.paddle.body.apply_force(cpv(-5000.0,0.0),cpv(40,15))
        end
        super
      end
    end
    class PaddleAssembly
      include CP::Object
      attr_reader :paddle, :break, :driver
      def initialize(p,static_body)
        @paddle = Paddle.new(p,static_body)
        @break  = Break.new(p,@paddle.body)
        #@driver = Driver.new(p,@paddle.body)
        init_chipmunk_object(@paddle,@break)#,@driver)
      end
    end
    class Paddle
      include CP::Object
      MASS = 2.0
      VERTICES = [
        cpv(-40,  0),
        cpv( 40, 20),
        cpv( 40,-20)
      ]
      MOMENT = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
      attr_reader :body, :shape
      def initialize(p,static_body)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p
        
        @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
        
        local_anchor = cpv(35,-15)
        world_anchor = @body.local2world(local_anchor)
        @hinge = CP::Constraint::PivotJoint.new(@body,static_body,local_anchor,world_anchor)
        init_chipmunk_object(@body,@shape,@hinge)
      end
    end
    class Break
      include CP::Object
      RADIUS = 2.0
      OFFSET = cpv(-25,20)
      attr_reader :body, :shape
      def initialize(p,paddle_body)
        @body = CP::StaticBody.new
        @body.p = p + OFFSET
        
        @shape = CP::Shape::Circle.new(@body,RADIUS,CP::vzero)
        @slide = CP::Constraint::SlideJoint.new(@body,paddle_body,CP::vzero,cpv(-25,0),0.0,50.0)
        init_chipmunk_object(@body,@shape,@slide)
      end
    end
    class Driver
      include CP::Object
      MASS = 1.0
      SIZE = 10
      VERTICES = [
        cpv(-SIZE, SIZE),
        cpv( SIZE, SIZE),
        cpv( SIZE,-SIZE),
        cpv(-SIZE,-SIZE)
      ]
      OFFSET_A = cpv(40,20)
      OFFSET_B = cpv(-SIZE,-SIZE)
      GROOVE_LENGTH = 50
      #MOMENT = Float::INFINITY
      MOMENT = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
      attr_reader :body,:shape
      def initialize(p,paddle_body)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = p + OFFSET_A - OFFSET_B
        
        @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
        
        @hinge = CP::Constraint::PinJoint.new(paddle_body,@body,OFFSET_A,OFFSET_B)
        
        @groove_body = CP::StaticBody.new
        @groove_body.p = @body.p
        a = cpv(-GROOVE_LENGTH,0)
        b = cpv( GROOVE_LENGTH,0)
        @groove = CP::Constraint::GrooveJoint.new(@groove_body,@body,a,b,CP::vzero)
        init_chipmunk_object(@body,@shape,@hinge,@groove_body,@groove)
      end
    end
    class Frame
      include CP::Object
      attr_reader :body
      def initialize
        @body = CP::StaticBody.new
        init_chipmunk_object(@body)
      end
    end
  end
end