require './chipmunk_extend'
require 'opengl'
require 'gosu'

# Dispatching for drawing shapes, to make things neater and not
# require typechecking the shape to find out what draw method to use.

module CP

	module Shape

		class Circle

			def draw(window)
			window.draw_circle_shape(self)
			end

		end

		class Segment
	
			def draw(window)
			window.draw_segment_shape(self)
			end
	
		end

		class Poly
	
			def draw(window)
			window.draw_poly_shape(self)
			end

		end

	end

	module Constraint

		def draw(window)
		window.draw_constraint(self)
		end

	end

	class Body

		def draw(window)
		#window.draw_vertex(self.p.x,self.p.y)
		end

	end

	module Object

		def draw(window)
		  if @chipmunk_objects
		    ## if this is a composite object, call draw() on primitives
			@chipmunk_objects.each {|obj| obj.draw(window)}
			end
		end
	
	end

	class Space
	  
		def draw(window)
		@chipmunk_objects.each {|obj| obj.draw(window)} ## dispatcher for chipmunk objects
		end
	
	end
  module DrawGL
      include GL, GLU, GLUT
      
      def gl_init
        glClearColor(1.0,1.0,1.0,1.0)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        glOrtho(0.0, 640.0, 480.0, 0.0, -1.0, 1.0)
        #glTranslatef(0.5, 0.5, 0.0)
        
        glEnableClientState(GL_VERTEX_ARRAY)
      end
      
      LINE_COLOR       = [0.0, 0.0, 0.0]
      COLLISION_COLOR  = [1.0, 0.0, 0.0]
      BODY_COLOR       = [0.0, 0.0, 1.0]
      CONSTRAINT_COLOR = [0.5, 1.0, 0.5]
      
      def glColor_from_pointer(obj)
        return glColor3f(0.0,0.0,0.0) unless self.options[:color]
        val = obj.object_id.hash.hash
        
        r = (val>>0) & 0xFF
        g = (val>>8) & 0xFF
        b = (val>>16) & 0xFF
        
        max = [r,g,b].max
        
        mult = 127
        add  =  63
         
        r = (r*mult)/max + add
        g = (g*mult)/max + add
        b = (b*mult)/max + add
        
        return glColor3ub(r,g,b)
        
      end
      
      
      CircleVAR = [
         0.0000,  1.0000,
         0.2588,  0.9659,
         0.5000,  0.8660,
         0.7071,  0.7071,
         0.8660,  0.5000,
         0.9659,  0.2588,
         1.0000,  0.0000,
         0.9659, -0.2588,
         0.8660, -0.5000,
         0.7071, -0.7071,
         0.5000, -0.8660,
         0.2588, -0.9659,
         0.0000, -1.0000,
        -0.2588, -0.9659,
        -0.5000, -0.8660,
        -0.7071, -0.7071,
        -0.8660, -0.5000,
        -0.9659, -0.2588,
        -1.0000, -0.0000,
        -0.9659,  0.2588,
        -0.8660,  0.5000,
        -0.7071,  0.7071,
        -0.5000,  0.8660,
        -0.2588,  0.9659,
         0.0000,  1.0000,
         0.0,     0.0 # For an extra line to see the rotation.
      ]
      CircleVAR.freeze
      CircleVAR_count = CircleVAR.length/2
      
      def draw_circle_shape(circle)
        body = circle.body
        glVertexPointer(2,GL_FLOAT,0,CircleVAR)
        
        glPushMatrix()
          center = body.p + circle.center.rotate(body.rot)
          glTranslatef(center.x,center.y,0.0)
          glRotatef(body.a*180.0/Math::PI, 0.0, 0.0, 1.0)
          glScalef(circle.radius, circle.radius, 1.0)
          
          glColor_from_pointer(circle)
          glDrawArrays(GL_TRIANGLE_FAN, 0, (CircleVAR_count-1))
          
          glColor3f(*LINE_COLOR)
          glDrawArrays(GL_LINE_STRIP, 0, CircleVAR_count)
        glPopMatrix()
      end
      
      PillVAR = [
         0.0000,  1.0000,
         0.2588,  0.9659,
         0.5000,  0.8660,
         0.7071,  0.7071,
         0.8660,  0.5000,
         0.9659,  0.2588,
         1.0000,  0.0000,
         0.9659, -0.2588,
         0.8660, -0.5000,
         0.7071, -0.7071,
         0.5000, -0.8660,
         0.2588, -0.9659,
         0.0000, -1.0000,
  
         0.0000, -1.0000,
        -0.2588, -0.9659,
        -0.5000, -0.8660,
        -0.7071, -0.7071,
        -0.8660, -0.5000,
        -0.9659, -0.2588,
        -1.0000, -0.0000,
        -0.9659,  0.2588,
        -0.8660,  0.5000,
        -0.7071,  0.7071,
        -0.5000,  0.8660,
        -0.2588,  0.9659,
         0.0000,  1.0000,
      ]
      PillVAR.freeze
      PillVAR_count = PillVAR.size/2
     
      def draw_segment_shape(seg)
        body = seg.body
        a = body.p + seg.a.rotate(body.rot)
        b = body.p + seg.b.rotate(body.rot)
      
        if (seg.radius != 0)
          delta = b - a
          len   = (delta.length)/(seg.radius)
        
          var = PillVAR.dup
          (0...PillVAR_count).step(2) do |i|
            var[i] += len
          end
        
          glVertexPointer(2, GL_FLOAT, 0, var)
          glPushMatrix()
            x = a.x
            y = a.y
            cos = delta.x/len
            sin = delta.y/len
          
            matrix = [
               cos, sin, 0.0, 0.0,
              -sin, cos, 0.0, 0.0,
               0.0, 0.0, 1.0, 1.0,
                 x,   y, 0.0, 1.0,
            ].freeze
          
            glMultMatrixf(matrix)
          
            glColor_from_pointer(seg)
            glDrawArrays(GL_TRIANGLE_FAN, 0, PillVAR_count)
          
            glColor3f(*LINE_COLOR)
            glDrawArrays(GL_LINE_LOOP, 0 , PillVAR_count)
          glPopMatrix()
        else
          glColor3f(*LINE_COLOR)
          glBegin(GL_LINES)
            glVertex2f(a.x,a.y)
            glVertex2f(b.x,b.y)
          glEnd()
        end
      end # end def drawSegmentShape
      
      def draw_poly_shape(poly)
        body = poly.body
        rot, p, o, verts = body.rot, body.p, poly.offset, poly.verts
        var = verts.map {|vo| v = vo.rotate(rot) + p + o; [v.x,v.y]}.flatten
      
        glVertexPointer(2,GL_FLOAT,0,var)
      
        glColor_from_pointer(poly)
        glDrawArrays(GL_TRIANGLE_FAN, 0, verts.size)
    
        glColor3f(*LINE_COLOR)
        glDrawArrays(GL_LINE_LOOP,0, verts.size)
      end
    
      def draw_object(obj)
        obj.draw(self)
      end
    
      SpringVAR = [
        0.00, 0.0,
        0.20, 0.0,
        0.25, 3.0,
        0.30,-6.0,
        0.35, 6.0,
        0.40,-6.0,
        0.45, 6.0,
        0.50,-6.0,
        0.55, 6.0,
        0.60,-6.0,
        0.65, 6.0,
        0.70,-3.0,
        0.75, 6.0,
        0.80, 0.0,
        1.00, 0.0,
      ].freeze
    
      SpringVAR_count = SpringVAR.length/2
    
      def draw_spring(spring,body_a,body_b)
        a = body_a.p + spring.anchr1.rotate(body_a.rot)
        b = body_b.p + spring.anchr2.rotate(body_b.rot)
      
        glPointSize(5.0)
        glBegin(GL_POINTS)
          glVertex2f(a.x,a.y)
          glVertex2f(b.x,b.y)
        glEnd()
      
        delta = b - a
      
        glVertexPointer(2,GL_FLOAT,0,SpringVAR)
        glPushMatrix()
          x   = a.x
          y   = b.y
          cos = delta.x
          sin = delta.y
          s   = 1.0/(delta.length)
        
          matrix = [
             cos,   sin, 0.0, 0.0,
          -sin*s, cos*s, 0.0, 0.0,
             0.0,   0.0, 1.0, 1.0,
               x,     y, 0.0, 1.0,
          ]
          matrix.freeze
        
          glMultMatrixf(matrix)
          glDrawArrays(GL_LINE_STRIP, 0, SpringVAR_count)
      end
    
      def draw_constraint(constraint)
        glColor3f(*CONSTRAINT_COLOR)
        body_a, body_b = constraint.body_a, constraint.body_b
      
        case constraint
        when CP::Constraint::PinJoint, CP::Constraint::SlideJoint
          a = body_a.p + constraint.anchr1.rotate(body_a.rot)
          b = body_b.p + constraint.anchr2.rotate(body_b.rot)
        
          glPointSize(5.0)
          glBegin(GL_POINTS)
            glVertex2f(a.x,a.y)
            glVertex2f(b.x,b.y)
          glEnd()
        
          glBegin(GL_LINES)
            glVertex2f(a.x,a.y)
            glVertex2f(b.x,b.y)
          glEnd()        
        when CP::Constraint::PivotJoint
          a = body_a.p + constraint.anchr1.rotate(body_a.rot)
          b = body_b.p + constraint.anchr2.rotate(body_b.rot)
        
          glPointSize(10.0)
          glBegin(GL_POINTS)
            glVertex2f(a.x,a.y)
            glVertex2f(b.x,b.y)
          glEnd()
        when CP::Constraint::DampedSpring
          self.draw_spring(constraint,body_a,body_b)
        #not implimented in ruby binding yet
        #when CP::Constraint::BreakableJoint
        #  self.draw_constraint(constraint.delegate)
        else
        end
      end # def drawConstraint
      def draw_BB(shape)
        bb = shape.bb
        l,r,t,b = bb.l, bb.r, bb.t, bb.b
      
        glBegin(GL_LINE_LOOP)
          glVertex2f(l,b)
          glVertex2f(l,t)
          glVertex2f(r,t)
          glVertex2f(r,b)
        glEnd()
      end
    
      def draw_collisions(*args)
        # can't get this data in ruby!
      end
    
      def draw_demo(demo,options)
  
      end
    end # end module DrawGL
end #module CP