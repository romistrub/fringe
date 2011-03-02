require 'opengl'
require 'gosu'

class Window < Gosu::Window
  ## Step II of automatic Gosu loop
  def draw
    clip_to(0, 0, 600, 400) do ## limits drawing area to the rectangle given
      gl {

        glClearColor(1.0,1.0,1.0,1.0)
          glMatrixMode(GL_PROJECTION)
          glLoadIdentity()
          glOrtho(0.0, 640.0, 480.0, 0.0, -1.0, 1.0)
          glTranslatef(0.5, 0.5, 0.0)
          glEnableClientState(GL_VERTEX_ARRAY)}  ## executes draw cascade in a clean GL environment
    end
  end
end

Window.new(600,400,false).show