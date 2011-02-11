require 'demo'

module ChipmunkDemos
  module WalkBot
    WALK_BOT_GROUP = 1
    class WalkBotDemo < Demo
      def initialize
        super
        @steps = 3
        @space.gravity = cpv(0.0,600.0)
        @space.iterations = 50
        @boundary = Boundary.new
        @bot = Bot.new(cpv(520,390))
        
        @space.add_objects(@boundary,@bot)
        @chipmunk_objects.push(@boundary,@bot)
      end
      def update
        coef = (2.0 + self.arrow_direction.y)/3.0
        rate = (self.arrow_direction.x*3.0*coef)
        @bot.motor.rate = rate
        super
      end
    end
    class Bot
      include CP::Object
      attr_reader :chassis,:motor
      MOTOR_SPEED = (2.0*Math::PI)/3.0
      def initialize(p)
        @chassis = Chassis.new(p)
        x_offset = Chassis::WIDTH - Crankshaft::RADIUS
        y_offset = -Crankshaft::RADIUS - 30.0
        @crank1  = Crankshaft.new(@chassis, cpv( x_offset,y_offset))
        @crank2  = Crankshaft.new(@chassis, cpv(-x_offset,y_offset))
        @motor   = CP::Constraint::SimpleMotor.new(@chassis.body,@crank1.body,MOTOR_SPEED)
        @gear    = CP::Constraint::GearJoint.new(@crank1.body,@crank2.body,0.0,1.0)
        @legs    = [
          Leg.new(@chassis,@crank1, Crankshaft::RADIUS),
          Leg.new(@chassis,@crank1,-Crankshaft::RADIUS),
          Leg.new(@chassis,@crank2, Crankshaft::RADIUS),
          Leg.new(@chassis,@crank2,-Crankshaft::RADIUS)
        ]
        
        init_chipmunk_object(@chassis,@crank1,@crank2,@motor,@gear,*@legs)
      end
    end
    class Chassis
      include CP::Object
      WIDTH  = 60.0
      HEIGHT = 20.0
      VERTS  = [
        cpv(-WIDTH,-HEIGHT),
        cpv(-WIDTH, HEIGHT),
        cpv( WIDTH, HEIGHT),
        cpv( WIDTH,-HEIGHT)
      ]
      MASS   =  5.0
      MOMENT = CP::moment_for_poly(MASS,VERTS,CP::vzero)
      ELASTICITY = 0.0
      FRICTION   = 1.0
      attr_reader :body,:shape
      def initialize(p)
        @body  = CP::Body.new(MASS,MOMENT)
        @body.p = p
        @shape = CP::Shape::Poly.new(@body,VERTS,CP::vzero)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        @shape.group = WALK_BOT_GROUP
        
        init_chipmunk_object(@body,@shape)
      end
    end
    class Leg
      include CP::Object
      MASS   =  2.0
      LENGTH = 40.0
      A = cpv(0.0,-LENGTH)
      B = cpv(0.0, LENGTH)
      MOMENT = CP::moment_for_segment(MASS,A,B)
      attr_reader :body,:shape,:foot
      def initialize(chassis,crank,offset)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = crank.body.p + cpv(0.0,LENGTH-offset)
        @shape = CP::Shape::Segment.new(@body,A,B,5.0)
        @shape.group = WALK_BOT_GROUP
        pivot  = CP::Constraint::PivotJoint.new(crank.body,@body,cpv(0.0,-offset),A)
        groove = CP::Constraint::GrooveJoint.new(@body,chassis.body,A,B,cpv(crank.body.p.x - chassis.body.p.x,0.0))
        @foot  = CP::Shape::Circle.new(@body,10.0,B)
        @foot.e = 0.0; @foot.u = 1.0
        @foot.group = 1
        
        init_chipmunk_object(@body,@shape,pivot,groove,@foot) 
      end
    end
    class Crankshaft
      include CP::Object
      MASS     =  1.0
      RADIUS   = 20.0
      MOMENT   = CP::moment_for_circle(MASS,RADIUS,0.0,CP::vzero)
      ELASTICITY = 0.0
      FRICTION = 1.0

      attr_reader :body, :shape, :joint
      def initialize(chassis,offset)
        @body = CP::Body.new(MASS,MOMENT)
        @body.p = chassis.body.p + offset
        
        @shape = CP::Shape::Circle.new(@body,RADIUS,CP::vzero)
        @shape.e = ELASTICITY
        @shape.u = FRICTION
        @shape.group = WALK_BOT_GROUP
        
        @joint = CP::Constraint::PivotJoint.new(chassis.body,@body,offset,CP::vzero)
        
        init_chipmunk_object(@body,@shape,@joint)
      end  
    end
    class Boundary
      include CP::Object
      VERTS = [
        cpv(  0,  0),
        cpv(  0,480),
        cpv(640,480),
        cpv(640,  0)
      ]
      ELASTICITY=FRICTION=1.0
      attr_reader :shapes, :body
      def initialize
        @body = CP::StaticBody.new
        @shapes = VERTS.enum_cons(2).map do |a,b|
          shape = CP::Shape::Segment.new(@body,a,b,0.0)
          shape.e = ELASTICITY
          shape.u = FRICTION
          shape
        end
        init_chipmunk_object(@body,*@shapes)
      end
    end
  end
end
    