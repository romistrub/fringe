class Demo
  
  def dt
    (1.0/60.0)/steps
  end
  
  attr_accessor :steps, :space, :chipmunk_objects, :arrow_direction
  def initialize
    CP::Shape.reset_id_counter
    @space = CP::Space.new
    @chipmunk_objects = []
    @steps = 3
    @arrow_direction = CP::vzero
  end
  
  def update
    self.steps.times do
      self.space.step(self.dt)
    end
  end
  
  DEFAULT_OPTIONS = {
    :color => true,
    :title => "Demo"
  }
  
  def options
    DEFAULT_OPTIONS.merge(
    (self.class.const_get(:OPTIONS) rescue {})
    )
  end

end

class TumbleScene < Scene

	def initialize

		super

		@tumbler = Tumbler.new
		@bricks = []

		for i in (0...3) do
			for j in (0...7) do
				@bricks << Brick.new(cpv(i*60 + 170, 390 - j*30))
			end
		end

		self.add_objects(@tumbler,*@bricks)
		self.add_collision_handler(:boxx, :boxx){|arbiter| puts arbiter.a 1 } ####R collision type 1 and 1

	end

	def bareback(&x)
	puts x
	end

	def update
		super

		@steps.times do
			@tumbler.update(self)
		end

	end

end #class TumbleScene

class Brick
include CP::Object

	VERTICES = [
	cpv(-30,-15),
	cpv(-30, 15),
	cpv( 30, 15),
	cpv( 30,-15)]
	MASS    = 1.0
	MOMENT  = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
	ELASTICITY = 0.0
	FRICTION   = 0.7

	attr_reader :body, :shape

	def initialize(p)

		@body = CP::Body.new(MASS,MOMENT)
		@body.p = p
		@shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
		@shape.e = ELASTICITY
		@shape.u = FRICTION
		@shape.collision_type = :boxx
		init_chipmunk_object(@body,@shape)

	end #initialize

end #class Brick

class Tumbler
include CP::Object

	VERTICES = [
	cpv(-200,-200),
	cpv(-200, 200),
	cpv( 200, 200),
	cpv( 200,-200)]
	ELASTICITY = FRICTION = 1.0
	SPIN = -0.8

	attr_reader :body, :shapes
	
	def initialize

		@body = CP::StaticBody.new
		@body.p = cpv(320,240)

		# Give the box a little spin.
		# Because staticBody is never added to the space, we will need to
		# update it ourselves (see update method).
		# NOTE: Normally you would want to add the segments as normal and not static shapes.
		# I'm just doing it to demonstrate the Space#rehash_static method.
		@body.w = SPIN

		@shapes = VERTICES.enum_cons(2).to_a.push([VERTICES[-1],VERTICES[0]]).map do |a,b|
		seg = CP::Shape::Segment.new(@body,a,b,0.0)
		seg.e = ELASTICITY
		seg.u = FRICTION
		seg
		end

		init_chipmunk_object(@body,*@shapes)

	end #initialize

	def update(demo)

		# Manually update the position of the static shape so that the box rotates.
		@body.update_position(demo.dt)

		# Because the box is added as a static shape and we moved it 
		# we need to manually rehash the static spatial hash.
		demo.space.rehash_static

	end

end #class Tumbler
