require 'opengl'
require 'gosu'
require './chipmunk_draw'

class Window < Gosu::Window
  include CP::DrawGL
  ## Step II of automatic Gosu loop
  def draw
    clip_to(0, 0, 600, 400) do ## limits drawing area to the rectangle given
      draw_rect(0, 0, 600, 400, Gosu::white) ## draws background
      gl {gl_init;}  ## executes draw cascade in a clean GL environment
    end
  end
end

Window.new(600,400,false).show