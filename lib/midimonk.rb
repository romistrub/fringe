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


### salt -- Sequencer Alternative
### v0.1 (codename: Arrhenius)
### v1.0 (codename: Lewis)
### a combination of chemistry, music, mathematics, and programming

### element
### stock/acid -- Input event set 1 (pH e.g. Chipmunk: Newtonian events (position, velocity, collision))
### stock/base -- Input event set 2 (e.g. MIDIator: MIDI events)
########### pKb is the library size, describes capacity to react in solution (haha)

### experiment

### stock/source -- taxonomy of species (e.g. keydown, keyup)
### species -- event prototype 
####### element < species
### atom -- a single event
### molecule -- a linked list of events (one element is the event and its links), associated with reactivity (e.g. pKa)
######-- def rotateional vibration:

############ ********** ##############
# Structure #
# Mixtures and pipes
# In the simplest prototype:
# 1) Chipmunk mixin Pipe. Pipe.input accepts a method that ChipmunkSource < Chipmunk mixin Source 
# pipe from stock to mixture
# 2) species are piped from stock into mixture as event occurs
# 3) 
# 2) mixture contains single solvent (probability of collision with solvent is always 1)
# 3) 
# input vs output pipes

### mixture -- solvent with concentrations of species
### --- contents (weighted array of molecules)
### --- def e 
###
### add component


### collision -- event listener -- determines reaction *(y/n) and mechanism based on properties of molecules
### mechanism -- a way to transform a molecule (reactant) into another molecule (product)
### --- def site
### precipitate -- events that can be piped into the OS or into another vessel
### evapourate -- events that should be discarded into the fume-hood (which can actually also pipe into OS)
### reaction --
####### intramolecular (same reactants)
####### intermolecular (different reactants)

### titration/drip --> drip into vessel

### lab
####### bench
####### drip
####### vessel
####### pipe --> interface between vessels

### intermediate

### collision -- depends on environment
### reaction --- depends on molecules
### precipitation

### precipitation --- depends on environment -- acquires some properties of the base, and some properties of the acid
### --- precipitate --- fundamental unit piped to the OS

### event macros



### reaction -- Interaction between acid and base
### 

### library has species, capacity
### mapping MIDI events to (MIDIator)
### pKb is the event density/probability, hydrophile, acceptor, prototype: Hydroxide
### acid -- Physics event list, pKa, electrophile, donator, protonator, prototype: Proton
### (high or low pHysics, pKa)
### solution is an instrument
### vessel/stage/lab -- reaction environment
### p
### hood -- GL
### water ---
### Watch the reaction. HCl = Chipmunk + , Metal. Lattice.
module Salt

	#### Salt::Scene is a Gosu::Window that draws a CP::Space
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
	
	### MidiMonk::Interface is a MIDIator::Interface that outputs CP::Space events as MIDI events and creates CP::Objects from MIDI input
	class Interface < MIDIator::Interface
	include CP::Play

	end

	class Synchro < MIDIator::Timer
	
	### Example instrument components:
	### Collider-ball
	### Key body: collision triggers key-down/up; channel, pitch (rough analogue of piano key)
	### Drum body: collision triggers key-down/up; channel, patch
	### Theremin space: channel, home pitch (pitch depends on contact location), borders change home-pitch
	### Mod-sink body: proximity to mod-object decreases modulation amount
	### Mod-source body: proximity to mod-object increases modulation amount
	### Pitch boundary: object within space determines object's pitch
	### Key 
	### Grid-based: 2D sequencer -- proximity could emphasize scales and note density
	### pit size corresponds to probability of random ball landing

	### A shortcut to create a windowed interface
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
