# This file adds some useful accessors to chipmunk that are present in the C
# Structs but not available in ruby. Note of course that we aren't accessing
# the C Structs directly here, but since the values we are trying to keep
# track of do not change over the life of a body or shape, it works out fine.
#require "prettyprint"
#puts $-d

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

# NODES, PRIMITIVES, CONSTRAINTS, SHAPES
# Nodes have N_TYPE (node type)
# Primitives have P_TYPE (primitive type)
# Parents have C_TYPES (child types)

module CP

  RUBY_ALIASES = {
    :constraint  => CP::Constraint,
    :body => CP::Body,
    :shape => CP::Shape
  }.collect {|name, o|
    o.const_set :RUBY_ALIAS, name
  }

  PRIMITIVES = [
    :Constraint,
    :Body,
    :Shape]
    
  NODES = [
    :Constraint,
    :Body,
    :Shape,
    :Composite,
    :Space]

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
  
  module Node
    
    def N_TYPE; self.class; end

    # As function compositions (T~ and T+ is T.pre_update and T.post_udpate resp.):
    # T(D) = [T+ A+ X+ X~ A~ T~, T+ A+ Y+ Y~ A~ T~, T+ A+ Z+ Z~ A~ T~, T+ B+ B~ T~](D)
    def update(result = nil)
      result = pre_update(result) if self.respond_to? :pre_update
      result = children.collect {|child| child.update result} if children
      result = post_update(result) if self.respond_to? :post_update
      result
    end
    
    module Child
      
      include Node
    
      attr_accessor :parent
    
      module Primitive
    
        include Child
     
      end
    
    end
    
    module Parent
      include Node
      
      def children() @children.values.flatten(1); end
      def categorize(objs) objs.group_by{|o| self.class.const_get(C_TYPES[o]).name}; end ################################################
      
      # Should be called during initialization of a CP::Object to set children
      # Injects CP::Object primitives into @chipmunk_object array with elements [self] or []     
      def add_children (*objs)
        children = @children || {}
        objs = categorize(objs)
        (children.keys | objs.keys).each {|key| @children[key] = objs[key] | children[key]}
        @children.each {|child| child.parent = self}
      end
      
      def remove_children (*objs)
        categorize(objs).each{|type, object|
          @children[type].delete(object)
        }
      end
    
    end

  end
    
  class  Body;
    include Node::Child::Primitive;
    P_TYPE = CP::Body;
  end

  module Constraint
    include Node::Child::Primitive;
    P_TYPE = CP::Constraint;
    CONSTRAINTS.each {|o| const_get(o).send(:include, Constraint)}
  end
 
  module Shape
    include Node::Child::Primitive;
    P_TYPE = CP::Shape;
    class Circle;   include Shape; trap_args :initialize, *[nil, :radius, :center]; end
    class Segment;  include Shape; trap_args :initialize, *[nil, :a, :b, :radius]; end
    class Poly;     include Shape; trap_args :initialize, *[nil, :verts, :offset]; end
  end   
     
  # Chipmunk Object refines Space structure to allow hierarchy
  # from Space > [Bodies, Static Shapes (.body), Active Shapes (.body), Constraints]
  # to Space > Children [Body, Shapes]
  # Components (one body and one+ shapes) are in +children+ array
  module Composite
    include Node::Child, Node::Parent
    C_TYPES = [CP::Body, CP::Shape, CP::Constraint]
    def bodies()      @children[:CP::Body];          end
    def shapes()      @children[:CP::Shape];         end
    def constraints() @children[:CP::Constraint];    end
    def body()        @children[:CP::Body].first();  end
  end
    
  class Space
    
    include Node::Parent
    C_TYPES = [CP::Body, CP::Shape, CP::Constraint, CP::Composite]

    def bodies()      @children[:CP::Body];          end
    def shapes()      @children[:CP::Shape];         end
    def constraints() @children[:CP::Constraint];    end
    def composites()  @children[:CP::Composite];     end 
    
    def add_children(*o) with_objects("add", *o); end
    def remove_children(*o) with_objects("remove", *o); end
    
    private
    
    alias_method :add_nodes, :add_children
    alias_method :remove_nodes, :remove_children
    
    # Use with_objects to perform object behaviour that is similar across child objects
    def with_objects(action, *objects)
      debug = "#{self.class}#with_object"
      
      command, prefix, primitives = case action
      when "add";     [:add_nodes,    "add_"]
      when "remove";  [:remove_nodes, "remove_"]
      else; raise ArgumentError.new "#{debug} [action] expects 'add'/'remove'; received #{action.inspect}"
      end    
      
      objects.each{|object|
        
        primitives = case
        when object.is_a?(Composite);  object.children
        when object.is_a?(Primitive);  [object]
        else; raise ArgumentError.new "#{self.class}#with_object expects (action, *objects): #{object.inspect} is not a valid object"
        end
      
        primitives.dispatch(self) {|primitive| prefix + primitive.class.const_get(:RUBY_ALIAS).to_s}
        object.parent = self;
        self.method(command).call(object)
      }
    end
 
  end
    
  class ArgumentError < ArgumentError
    def initialize(context, arg, expected, received)
      super "#{context.class} [#{arg}] expects #{expected.inspect}; received #{received.inspect}"
    end
  end
end