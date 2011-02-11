require 'chipmunk_object'

module Math
  RAD2DEG  = 360.0/(2.0*PI)
  RAD2GRAD = 400.0/(2.0*PI)
end

module CP
  module Transform
    class Stack
      def initialize()
        @stack = []
      end
      
      def translate(vec)
        @stack.unshift(Translation.new(vec))
        return self
      end
      
      def rotate(angle)
        @stack.unshift(Rotation.new(angle))
        return self
      end
      
      # Scales a shape; the factor must be positive.
      def scale(factor)
        @stack.unshift(Scalation.new(factor))
        return self
      end
      
      def reflect(axis)
        @stack.unshift(Reflection.new(axis))
        return self
      end
      
      m = [:position,:angle,:shape_offset,:radius,:endpoints,
            :vertices,:component_offset
      ]
      m.each do |method|
        define_method(method) do |arg|
          @stack.inject(arg) do |arg,transform|
            transform.send(method,arg)
          end
        end
      end
    end
    class Transformation
      def position(pos) pos end
      def angle(angle) angle end
      def shape_offset(off) off end
      def radius(rad) rad end
      def endpoints(pts) pts end
      def vertices(verts) verts end
      def component_offset(off) off end
    end
    class Translation < Transformation
      def initialize(vec)
        @vector = vec
      end
      def position(pos)
        return pos + @vector
      end
    end
    class Rotation < Transformation
      def initialize(angle)
        @angle = angle
        @cpv = CP::Vec2.for_angle(@angle)
      end
      def angle(angle)
        return angle + @angle
      end
      def component_offset(off)
        return off.rotate(@cpv)
      end
    end
    class Scalation < Transformation
      def initialize(factor)
        @factor = factor
      end
      def shape_offset(off)
        return off * @factor
      end
      def radius(rad)
        return rad * @factor
      end
      def endpoints(pts)
        return pts.map {|pt| pt * @factor}
      end
      def vertices(verts)
        return verts.map {|vert| vert * @factor}
      end
      def component_offset(off)
        return off * @factor
      end
    end
    class Reflection < Transformation
      def initialize(axis)
        raise(ArgumentError, "Axis must be either :x or :y!") unless [:x,:y].include? axis
        @axis = axis
      end
      def ref_vec(vec)
        return case @axis
        when :x: CP::Vec2.new(-off.x,off.y)
        when :y: CP::Vec2.new(off.x,-off.y)
        end
      end
      def shape_offset(off)
        return self.ref_vec(off)
      end
      def endpoints(pts)
        return pts.map {|pt| self.ref_vec(pt)}
      end
      def vertices(verts)
        return verts.reverse.map {|vert| self.ref_vec(vert)}
      end
      def component_offset(off)
        return self.ref_vec(off)
      end
    end
  end
end