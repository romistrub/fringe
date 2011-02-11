#!/usr/bin/env ruby

require 'enumerator'

# Added for consistency between 1.8 and 1.9. Just ignore it.
unless [].respond_to?(:enum_cons)
  module Enumerable
    alias :enum_cons :each_cons
    alias :enum_slice :each_slice
  end
end
unless 'a'.respond_to?(:ord)
  class String
    def ord
      self[0]
    end
  end
end

require 'chipmunk_draw'

module MidiMonk

	#### MidiMonk::Scene is a Gosu::Window that draws a CP::Space
	class Window < Gosu::Window
	include CP::DrawGL

		DEFAULT_OPTIONS = {
		:color => true,
		:title => "new scene"
		}

		attr_accessor :steps, :chipmunk_objects, :arrow_direction

		def initialize(space, args = {
				steps: 3,			## chipmunk steps per gosu window update
				size: [600,400],
				caption: "new window",
			})

			@space = space
			super(*args[:size], false)
			@caption =  args[:caption]

			@arrow_direction = CP::vzero ## only applicable when there's a window to capture the keyboard

			@steps = args[:steps]
		end

		def update

			self.set_arrow_direction
			self.steps.times {
				@space.step(self.dt)
			} # rehash static?

		end

		def draw

			self.clip_to(0,0,self.width,self.height) do ## limits drawing area to the rectangle given

				self.draw_rect(0,0,self.width,self.height,Gosu::white) ## draws background
				self.gl do ## executes block in a clean GL environment
					gl_init
					@space.draw(self) ## start the drawing cascade
				end #do

			end #do

		end #draw

		def options
		DEFAULT_OPTIONS.merge((self.class.const_get(:OPTIONS) rescue {}))
		end

		def dt
		(1.0/60.0)/steps
		end

		def button_down(id)

			if id == Gosu::KbEscape
			close
			end

		end

		def set_arrow_direction

			x,y = 0,0
			y += 1 if self.button_down?(Gosu::KbUp)
			y -= 1 if self.button_down?(Gosu::KbDown)
			x += 1 if self.button_down?(Gosu::KbRight)
			x -= 1 if self.button_down?(Gosu::KbLeft)
			@scene.arrow_direction = cpv(x,y)

		end

		def mouse_clicked

			x,y = self.mouse_x,self.mouse_y
			loc = self.gosu_to_chipmunk(x,y)
			# No shape_point_query right now in the ruby binding. Something else
			# for now.

		end

		def gosu_to_chipmunk(x,y)
		result = cpv(x-self.width/2,self.height/2)
		end

		def centerx
		0
		end

		def centery
		0
		end

	end
	
	### MidiMonk::Interface is a MIDIator::Interface that outputs CP::Space events as MIDI events
	class Interface < MIDIator::Interface
	include CP::Play

	end

	class Instrument < CP::Space
		def initialize(*args)
				active_hash: [30.0,999],	## active hash dimensions and count
				static_hash: [200.0,99],	## static hash dimensions and count
				gravity: [0,600],		## gravity vector

			super
			self.resize_active_hash(*args[:active_hash])
			self.resize_static_hash(*args[:static_hash])
			self.gravity = cpv(*args[:gravity])

			CP::Shape.reset_id_counter
		end
	end

end


MidiMonk::Scene.new.window.show ## starts "modal loop" of MidiMonk::Window update/draw
