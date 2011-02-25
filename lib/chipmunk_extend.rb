# This file adds some useful accessors to chipmunk that are present in the C
# Structs but not available in ruby. Note of course that we aren't accessing
# the C Structs directly here, but since the values we are trying to keep
# track of do not change over the life of a body or shape, it works out fine.

require 'chipmunk'

def cpv(x,y)
  CP::Vec2.new(x,y)
end

module CP

	def self.vzero
	cpv(0.0,0.0)
	end

	def self.vlerp(v1,v2,t)
	(v1*(1.0-t))+(v2*t)
	end

	def self.moment_for_segment(mass,a,b)
	length = (a-b).length
	offset = ((a+b)*(0.5))
	return ((mass*length*length)/12.0) + (mass * (offset.dot offset))
	end

	# Chipmunk Object

	# Manages composite objects using chipmunk_objects array, containing primitive Chipmunk objects (e.g. bodies, shapes and constraints).
	# Primitive objects inherit chipmunk_objects array, but override to return self as single-element
	# Static objects return empty array
	# Composite objects with primitive children must +include CP::Object+ and call +init_chipmunk_object(*children)

	# Objects +add_to_space+ contextually, so the space can indiscriminately +add_object+ without type-checking
	module Object
		
		# Returns the list of primitive Chipmunk objects (bodies, shapes and constraints)
		def chipmunk_objects

			if @chipmunk_objects
				return @chipmunk_objects
			else
				raise "This CP::Object (#{self.class}) did not call #init_chipmunk_object."
			end

		end
		
		private
		
		# Should be called during initialization of a CP::Object to set children
		# Injects CP::Object primitives into @chipmunk_object array with elements [self] or [] 
		def init_chipmunk_object(*objs)
		bad_objs = objs.reject{|obj| obj.is_a?(CP::Object)} # objs must be a CP::Object
		raise(ArgumentError, "The following objects: #{bad_objs.inspect} are not CP::Objects") unless bad_objs.empty?
		@chipmunk_objects = objs.inject([]){|sum, obj| sum + obj.chipmunk_objects}.uniq
		end
		
		def reset_forces
  		@chipmunk_objects.each do |obj|
  			obj.reset_forces if obj.is_a?(Body)
  		end
		end

	end
	
	class Body
	include CP::Object

		def chipmunk_objects
		[self]
		end
		
		def add_to_space(space)
		space.add_body(self)
		end
		
		def remove_from_space(space)
		space.remove_body(self)
		end

	end

	class StaticBody < Body

		def initialize
		super(Float::INFINITY, Float::INFINITY)
		end
		
		def chipmunk_objects
		# return [] instead of [self] so the static body will not be added.
		[]
		end

	end
	
	module Shape
	include CP::Object
		
		def chipmunk_objects
		[self]
		end
		
		def add_to_space(space)
		space.add_shape(self)
		end
		
		def remove_from_space(space)
		space.remove_shape(self)
		end

		class Circle

			attr_reader :radius, :center
			alias_method :orig_init, :initialize

			def initialize(body, radius, center)
			@radius, @center = radius, center
			orig_init(body,radius,center)
			end

		end

		class Segment

			attr_reader :a, :b, :radius
			alias_method :orig_init, :initialize

			def initialize(body, a, b, radius)
			@a, @b, @radius = a, b, radius
			orig_init(body,a,b,radius)
			end

		end

		class Poly

			attr_reader :verts, :offset
			alias_method :orig_init, :initialize

			def initialize(body, verts, offset)
			@verts, @offset = verts, offset
			orig_init(body,verts,offset)
			end

		end
	end

	module StaticShape
	include Shape
		
		def add_to_space(space)
		space.add_static_shape(self)
		end
		
		def remove_from_space(space)
		space.remove_static_shape(self)
		end

		class Circle < Shape::Circle
		include StaticShape
		end
		
		class Segment < Shape::Segment
		include StaticShape
		end
		
		class Poly < Shape::Poly
		include StaticShape
		end

	end
		
	module Constraint
	include CP::Object
	
		def chipmunk_objects
		[self]
		end
	
		def add_to_space(space)
		space.add_constraint(self)
		end
	
		def remove_from_space(space)
		space.remove_constraint(self)
		end
	
	end
	
	class Space
		
		alias_method :orig_init, :initialize
		
		def initialize(*args)
		orig_init(*args)
		@chipmunk_objects = [] # top level chipmunk_objects
		end

		## add all obj.chipmunk_objects to space
		## default chipmunk_objects is [self] (or [] for static), but may be overridden with children 
		def add_object(obj)
		@chipmunk_objects.push (obj) ## composite objects are added as a single object
		obj.chipmunk_objects.each{|elt|	elt.add_to_space(self) } ## object's pieces are added to space
		end
	
		def add_objects(*objs)
		objs.each{|obj| add_object(obj)}
		end
	
		def remove_object(obj)
		obj.chipmunk_objects.each{|elt| elt.remove_from_space(self)}
		end
	
		def remove_objects(*objs)
		objs.each{|obj| remove_object(obj)}
		end

	end

end
