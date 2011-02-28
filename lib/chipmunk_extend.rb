# This file adds some useful accessors to chipmunk that are present in the C
# Structs but not available in ruby. Note of course that we aren't accessing
# the C Structs directly here, but since the values we are trying to keep
# track of do not change over the life of a body or shape, it works out fine.
#require "prettyprint"

# META
class Array
  # Pass each array element +i+ to a function [ obj.(resolver i) i ]
  def dispatch(o, &resolver) self.collect {|i| o.send(resolver.call(i), i)}; end
  def self.i(n) self.new(n).fill{|i| i}; end
end

class Symbol
  def + (sym)
    (self.to_s + sym.to_s).to_sym
  end
end

class Module
  def intercept_method(f, interceptor)
    alias_method o="old_#{f}", f.to_sym
    module_eval("def #{f}(*a,&b) aa=a&&a.clone; bb=b&&b.clone;"+interceptor+";#{o}(*aa,&bb);end")
  end
  def trap_args (f, *x)
    attr_reader *(x.compact)
    intercept_method f, Array.i(x.size).collect! {|i| "@#{x[i]} = a[#{i}];" if x[i] != nil }.join
  end
end

require 'chipmunk-ffi'
include CP

module CP
  
  PRIMITIVES = [
   :Constraint,
   :Body,
   :Shape]
  
  CONSTRAINTS = [
  :DampedRotarySpring,
  :DampedSpring,
  :GearJoint,
  :GrooveJoint,
  :PinJoint,
  :PivotJoint,
  :RatchetJoint,
  :RotaryLimitJoint,
  :SimpleMotor,
  :SlideJoint]
  
  SHAPES = [
   :Circle,
   :Segment,
   :Poly]

	# Chipmunk Object refines Space structure to allow hierarchy
  # from Space > [Bodies, Static Shapes (.body), Active Shapes (.body), Constraints]
  # to Space > Children [Body, Shapes]
	# Components (one body and one+ shapes) are in +children+ array
	module Composite
		
		def children() @children rescue raise "This CP::Object (#{self.class}) did not call #add_children."; end
		def parent() @parent rescue raise "This CP::Object (#{self.class}) was not added using #add_children."; end
    def body; @body; end
    def shapes; @shapes; end
          
		# Returns flat array of children
	  # [a.children, {|i| a.children[i].children}, {|i,j| a.children[i].children[j].children}, ..].flatten
    # e.g. [CP::Object, [[CP::Body], [CP::Shape], [CP::Shape]], []]
		def descendants() children + (children.collect{|c|c.ancestors}.flatten unless self.is_a Primitive); end
		
		# Returns array of ancestors
		# [a.parent, a.parent.parent, a.parent.parent.parent, ..]
		def ancestors() [parent] + (parent.ancestors if parent.respond_to? :parent); end
		
		# The recursive update() code is a bitch to understand! Here's some help:
		# let T{A{X, Y, Z}, B} be a CP::Object hierarchy called from C(ontext) like T.update()
		# As function compositions (T~ and T+ is T.pre_update and T.post_udpate resp.):
		# T(D) = [T+ A+ X+ X~ A~ T~, T+ A+ Y+ Y~ A~ T~, T+ A+ Z+ Z~ A~ T~, T+ B+ B~ T~](D)
		def update(downward_result = nil)
      downward_result = pre_update(downward_result) if self.respond_to? :pre_update
		  upward_result = children.collect {|child| child.update downward_result} unless self.is_a? Primitive
      upward_result = post_update(upward_result) if self.respond_to? :post_update
      upward_result
    end
    		
		# Should be called during initialization of a CP::Object to set children
		# Injects CP::Object primitives into @chipmunk_object array with elements [self] or [] 
		def children= (objs)
      bad_objs = objs.reject{|o|o.is_a?CP::Object}
  		raise(ArgumentError, "Objects: #{bad_objs.inspect} are not CP::Objects") unless bad_objs.empty?
		  @body = objs.collect{|o|o if o.is_a?CP::Body}.first
		  @shapes = objs.collect{|o|o if o.is_a?CP::Shape}
  		@children = objs.each {|child| child.parent = self}
		end

		def method_missing(name, *args)
		  @body.method(name).call *args rescue "No method #{name} for #{self.class} or #{self.body.class}"
		end
		    def parent= (obj) @parent=obj;
      puts "#{self.class}.parent = #{obj.class}"
      sleep 1; end
		protected
		
    module Primitive
    include Object
      def children() [self]; end
    end
  
	end
	
	# SET CLASSES/MODS AS PRIMITIVE	
  PRIMITIVES.each {|o| CP::const_get(o).send(:include, Object::Primitive)}
  SHAPES.each {|o| CP::Shape.const_get(o).send(:include, Shape)}
  CONSTRAINTS.each {|o| CP::Constraint.const_get(o).send(:include, Constraint)}
 
   # AND PAREMETER HOOKS
    module Shape
      Circle.trap_args :initialize, *[nil, :radius, :center]
      Segment.trap_args :initialize, *[nil, :a, :b, :radius]
      Poly.trap_args :initialize, *[nil, :verts, :offset]
    end

	class Space
    intercept_method :initialize, "@children=[]"
	  def update(args) @children.collect {|child| child.update args}; end
	  def add_object(*o) object(true, *o); end
	  def remove_object(*o) object(false, *o); end
		def object(add, *o) # expects composite objects
		  o.each{|oi| # for each composite object
		    oi.children.dispatch(self) {|c|
		      ((add ? "add_":"remove_")+c.class.const_get(:RUBY_ALIAS).to_s)
		    }
		    oi.parent = self; 
		    @children.send((add ? :push : :delete), oi)
		  }
		end
	end

# SET RUBY ALIASES FOR EACH CP CLASS/MOD
    RUBY_ALIASES = {
      constraint: Constraint,
      body: Body,
      shape: Shape
    }.collect {|name, o|
      o.const_set :RUBY_ALIAS, name
    }
	
end
