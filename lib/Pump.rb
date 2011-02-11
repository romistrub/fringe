require 'demo'

module ChipmunkDemos
  module Pump
    class PumpDemo < Demo
      OPTIONS = {
        :title => "Pump Demo"
      }
      NUM_BALLS = 4
      def initialize
        super
        @steps = 2
        @space.gravity = cpv(0,600)
        @scaffolding = Scaffolding.new
        @plunger = Plunger.new(cpv( 160,320))
        @balls = Array.new(NUM_BALLS) {|i| Ball.new(cpv( 96,160-64*i))}
        @small_gear = Gear.new(10, 80,cpv(160,400),@scaffolding.body,-Math::PI/2)
        @big_gear   = Gear.new(40,160,cpv(400,400),@scaffolding.body, Math::PI/2)
        # Connect the plunger to the small gear.
        @pin1 = CP::Constraint::PinJoint.new(@small_gear.body,@plunger.body,cpv(-80,0),CP::vzero)
        # Connect the gears.
        @teeth = CP::Constraint::GearJoint.new(@small_gear.body,@big_gear.body,-Math::PI/2,-2.0)
        @feeder = Feeder.new(@scaffolding.body)
        anchr = @feeder.body.world2local(cpv( 96.0,400.0))
        @pin2 = CP::Constraint::PinJoint.new(@feeder.body,@small_gear.body,anchr,cpv(0.0,80.0))
        @motor = CP::Constraint::SimpleMotor.new(@scaffolding.body,@big_gear.body,3.0)
        
        @space.add_objects(@scaffolding,@plunger,@small_gear,@big_gear,@pin1,@teeth,@feeder,@pin2,@motor,*@balls) 
        @chipmunk_objects.push(@scaffolding,@plunger,@small_gear,@big_gear,@pin1,@teeth,@feeder,@pin2,@motor,*@balls)
      end
      def update
        coef = (2.0 + self.arrow_direction.y)/3.0
        rate = (self.arrow_direction.x*30.0*coef)
        @motor.rate = rate
        @motor.max_force = (rate == 0 ? 0.0 : 1000000.0)
        self.steps.times do
          self.space.step(self.dt)
          @balls.each do |ball|
            if ball.body.p.x > 640.0
              ball.body.v = CP::vzero
              ball.body.p = cpv( 96.0, 40.0)
            end
          end
        end
      end
    end
    
    class Feeder
      include CP::Object
      BOTTOM = 540.0
      TOP    = 208.0
      MASS   =   1.0
      MOMENT = CP::moment_for_segment(MASS,cpv( 96,BOTTOM),cpv( 96,TOP))
      attr_reader :body
      def initialize(static_body)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = cpv( 96,(BOTTOM+TOP)/2.0)
        half_len = (BOTTOM-TOP)/2
        @shape = CP::Shape::Segment.new(@body,cpv(0.0,-half_len),cpv(0.0,half_len),20.0)
        pivot = CP::Constraint::PivotJoint.new(static_body,@body,cpv(96.0,BOTTOM),cpv(0.0,half_len))
        
        init_chipmunk_object(@body,@shape,pivot)
      end
    end
    
    
    class Ball
      include CP::Object
      MASS = 1.0
      RADIUS = 30
      MOMENT = CP::moment_for_circle(MASS,RADIUS,0,CP::vzero)
      attr_reader :shape, :body
      def initialize(pos)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = pos
        
        @shape = CP::Shape::Circle.new(@body,RADIUS,CP::vzero)
        @shape.e = 0.0; @shape.u = 0.5
        
        init_chipmunk_object(@body,@shape)
      end
    end
    
    class Gear
      include CP::Object
      attr_reader :body, :shape
      def initialize(mass,radius,pos,static_body,angle)
        @body = CP::Body.new(mass,CP::moment_for_circle(mass,radius,0,CP::vzero))
        @body.p = pos
        @body.angle = angle
        @shape = CP::Shape::Circle.new(@body,radius,CP::vzero)
        @shape.layers = 0
        pivot = CP::Constraint::PivotJoint.new(static_body,@body,pos,CP::vzero)
        
        init_chipmunk_object(@body,@shape,pivot)
      end
    end
    
    class Plunger
      include CP::Object
      VERTICES = [
        cpv( 30, 80),
        cpv( 30,-64),
        cpv(-30,-80),
        cpv(-30, 80)
      ]
      MASS = 1.0
      MOMENT = Float::INFINITY
      attr_reader :shape, :body
      def initialize(pos)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = pos
        @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
        @shape.e = 1.0; @shape.u = 0.5; @shape.layers = 1;
        
        init_chipmunk_object(@body,@shape)
      end
    end
    
    class Scaffolding
      include CP::Object
      SCAFFOLD_POINTS = [
        cpv( 64,224),cpv( 64,  0),
        cpv( 64,224),cpv(128,240),
        cpv(128,240),cpv(128,304),
        cpv(192,304),cpv(192, 96),
        cpv(128,160),cpv(128, 64),
        cpv(128, 64),cpv(192,  0),
        cpv(192, 96),cpv(512,176)
      ]
      attr_reader :body
      def initialize
        @body = CP::StaticBody.new
        @shapes = SCAFFOLD_POINTS.enum_slice(2).map do |a,b|
          shape = CP::Shape::Segment.new(@body,a,b,2.0)
          shape.e = 1.0; shape.u = 0.5; shape.layers = 1
          shape
        end
        init_chipmunk_object(@body,*@shapes)
      end
    end # class Scaffolding
    
  end # module Pump
end # module ChipmunkDemos