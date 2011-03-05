require './Salt'
require './Music'
require './chipmunk_system'
require "ruby-prof"; RubyProf.start
require 'ruby-debug'; Debugger.start

class TumbleSystem < CP::System
  attr_reader :bricks, :tumbler
  def initialize

    super
    self.gravity = vec2(0, 400)
    @tumbler = Tumbler.new
    @bricks = []
    @bricks << Brick.new(vec2(240, 320),2)
    @bricks << Brick.new(vec2(150, 320),3)
    @bricks << Brick.new(vec2(160, 240),4)
    @pin0 = Constraint::PinJoint.new(@tumbler.body, @bricks[0].body, zero, zero)
    @pin1 = Constraint::PinJoint.new(@bricks[0].body, @bricks[1].body, zero, zero)
    @pin2 = Constraint::PinJoint.new(@bricks[1].body, @bricks[2].body, zero, zero)
    self.add_children @tumbler, *@bricks
    self.add_children @pin0, @pin1, @pin2
    #self.add_collision_handler(:boxx, :boxx){|arbiter| puts arbiter.a 1 } ################## add to input here

  end

end #class TumbleScene

class Brick
include CP::Composite

  VERTICES = [
  vec2(-15,-15),
  vec2(-15, 15),
  vec2( 15, 15),
  vec2( 15,-15)]

  def initialize(p,l)

    body = Body.new(1.0, moment_for_poly(1.0,VERTICES,zero))
    body.p = p
    body.v = vec2(0,800)
    
    shape = Shape::Poly.new(body,VERTICES,zero)
    shape.e = 0.8
    shape.u = 0.1
    shape.layers = l
    
    self.add_children body, shape
  
  end #initialize

end #class Brick

class Tumbler
include CP::Composite

  def initialize

    body = StaticBody.new
    body.p = vec2(320,240)
    body.w = 0
    
    segments = Path.circle(body, 1, 20, 100){|segment|
      segment.e = 1.0
      segment.u = 1.0
      #segment.surface_v = vec2(100,0)
    }

    self.add_children body, *segments

  end #initialize

  def post_update(params)
    body.update_position(parent.dt)
    parent.rehash_static
  end

end #class Tumbler

=begin
All machines have input and output. Everything in between is some sort of processor.
This machine translates a string of text from the console into MIDI messages.

TD DO
- Read from shared memory (e.g. a pipe in Linux)
- Only write machine activity logs to console
- MIDI matrix composition using layered affectors
=end

### INITIALIZE WINDOW
spindoc = TumbleSystem.new.start
scene = spindoc.to_scene({:title => "Chipmunk to MIDI"})
scene.show
#scene.add_listener (Gosu::KbR) {system.reverse_momentum}

### INITIALIZE MIDI INTERFACE
midi = MIDIator::Interface.new
midi.autodetect_driver
midi.instruct_user!

###############
### MACHINE ###
###############

### INPUT
ip=NA::CL::Input.new.

### PROCESSOR: "hey how are you" --> ["hey" "how" "are" "you"]
to NA::CL::Membrane.new{|atom|
  atom.split  # haha BOOM 
}.

### PROCESSOR+DELAY: "enoughschoolworkalreadymkay" --> ["en" "ough" "schoolw" "ork" "alr" "eady" "mkay"]
to NA::CL::Vessel.new({period: 3}){|atom|
  atom.scan(/[^aeiouAEIOU]*[aeiouAEIOU]+[^aeiouAEIOU]{0,2}/)
}.

### TRANSLATOR
to NA::CL::Membrane.new{|atom|
  v = NArray[*atom.bytes.entries]                     # Numerical Array of string
  scale = ((HMINOR.p C5)+(MAJOR.p C6)+(HMINOR.p C7))  # musical scale, including C5 Harmonic Minor, etc.
  output = {
    channel:    1,
    note:       scale.seek((v.max.to_f-65)/57),       # pitch (limited by scale) ~ max letter
    duration:   v.size,                               # duration ~ size of string
    velocity:   v[0]                                  # velocity ~ first letter
  }
}.

### OUTPUT
to midi

###################
### MAIN THREAD ###
###################

main_thread = Thread.new {loop {ip.add gets.chomp}} # basic text input

main_thread.join
NA::CL.threads.entries.each{|e|e.join}
CP::System.threads.entries.each{|e|e.join}