module CP
  
  # Some colors to use. Note that at the moment COLLISIONS isn't used, since
  # the ruby version of Chipmunk does not yet provide the necessary level of
  # access to detailed collision information (i.e. see the difference between
  # the add_collision_func method in ruby and the cpSpaceAddCollisionPairFunc
  # function in C).
  LINES = ::Gosu::black
  VERTICES = ::Gosu::blue
  COLLISIONS = ::Gosu::red
  
  # This module encompases methods for drawing primitive Chipmunk shapes:
  # Segments, Circles and Polygons, as well as a few other drawing tools.
  module DrawPrimitives
    
    # Some basic drawing shortcuts I like to use.
    def draw_rect(x,y,w,h,c)
      self.draw_quad(x,y,c,x+w,y,c,x,y+h,c,x+w,y+h,c)
    end
    
    def draw_point(x,y,c)
      self.draw_rect(x-1,y-1,3,3,c)
    end
    
    # Draws a point at an offset, in the color assigned for vertices.
    def draw_vertex(x,y)
      self.draw_point(x,y,VERTICES)
    end
    
    # The following methods are my translations of the MoonBuggy demo's
    # Circle, Polygon and Segment drawing code. They have been lightly
    # rubified (the C version used for loops rather than chained enumerations)
    # and use Gosu drawing rather than OpenGL primitives, but are otherwise
    # the same.
    def draw_circle_shape(circle)
      body = circle.body
      c = body.p + circle.center.rotate(body.rot)
      self.draw_circle(c.x,c.y,circle.radius,body.a)
    end
    
    def draw_circle(x,y,r,a)
      segs = 15
      coef = 2.0*Math::PI/(segs.to_f)
      
      Array.new(15) do |n|
        rads = n*coef
        [r*Math.cos(rads+a) + x,r*Math.sin(rads + a) + y]
      end.each_cons(2) do |v1,v2|
        self.draw_line(v1[0],v1[1],LINES,v2[0],v2[1],LINES)
      end
    end
    
    def draw_segment_shape(seg)
      body = seg.body
      
      a = body.p + seg.a.rotate(body.rot)
      b = body.p + seg.b.rotate(body.rot)
      self.draw_line(a.x,a.y,LINES,b.x,b.y,LINES)
    end
    
    def draw_poly_shape(poly)
      body = poly.body
      verts = poly.verts
      ary = verts.map {|v| body.p + poly.offset + v.rotate(body.rot)}
      segs = ary.enum_cons(2).to_a << [ary[-1],ary[0]]
      segs.each do |v1,v2|
        self.draw_line(v1.x,v1.y,LINES,v2.x,v2.y,LINES)
      end
    end
    
  end
end