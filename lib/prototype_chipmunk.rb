require './Salt'
require './Music'
require './chipmunk_system'

class Tumble < CP:System

  def initialize

    super

    @tumbler = Tumbler.new
    @bricks = (0...3).collect {|i| (0...7).collect{|j| Brick.new(cpv(i*60 + 170, 390 - j*30))}}.flatten(1)

    self.add_objects(@tumbler,*@bricks)
    self.add_collision_handler(:boxx, :boxx){|arbiter| puts arbiter.a 1 } ################## add to input here

  end

end #class TumbleScene

class Brick
include CP::Object

  VERTICES = [
  cpv(-30,-15),
  cpv(-30, 15),
  cpv( 30, 15),
  cpv( 30,-15)]
  MASS    = 1.0
  MOMENT  = CP::moment_for_poly(MASS,VERTICES,CP::vzero)
  ELASTICITY = 0.0
  FRICTION   = 0.7

  attr_reader :body, :shape

  def initialize(p)

    @body = CP::Body.new(MASS,MOMENT)
    @body.p = p
    @shape = CP::Shape::Poly.new(@body,VERTICES,CP::vzero)
    @shape.e = ELASTICITY
    @shape.u = FRICTION
    @shape.collision_type = :boxx
    init_chipmunk_object(@body,@shape)

  end #initialize

end #class Brick

class Tumbler
include CP::Object

  VERTICES = [
  cpv(-200,-200),
  cpv(-200, 200),
  cpv( 200, 200),
  cpv( 200,-200)]
  ELASTICITY = FRICTION = 1.0
  SPIN = -0.8

  attr_reader :body, :shapes
  
  def initialize

    @body = CP::Body.new
    @body.p = cpv(320,240)
    @body.w = SPIN
    @shapes = VERTICES.enum_cons(2).to_a.push([VERTICES[-1],VERTICES[0]]).map do |a,b|
      seg = CP::Shape::Segment.new(@body,a,b,0.0)
      seg.e = ELASTICITY
      seg.u = FRICTION
      seg
    end
    init_chipmunk_object(@body,*@shapes)

  end #initialize

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
spindoc = Tumble.new
scene = spindoc.to_scene({title: "Chipmunk to MIDI"})
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