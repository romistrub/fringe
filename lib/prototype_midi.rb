require 'midiator'
require 'narray'
require './Salt.rb'
include MIDIator::Notes
include MIDIator::Scales


class Array
  def seek(dec) # accepts [0,1) (not including 1)
    fetch((size*dec).to_int)
  end
  def position(el) # returns position in (0,1) of "centre" of element (think of array as discrete dimension)
    (2*index(el) + 1) / (2*size)
  end
  def like(el, ary) # returns 
    seek(ary.position(el))
  end
  def p(num)
    map{|el|el+num}
  end
  def x(num)
    map{|el|el*num}
  end
  def e(num)
    + p(num)
  end
end

# play: note, duration, channel, velocity
class MIDIator::Interface
include NA::CL::Output
  def from_atom(atom)
    puts "PLAY: " + atom.inspect
    Thread.new {self.play(atom[:note], atom[:duration], atom[:channel], atom[:velocity])}
  end
end

Thread::abort_on_exception = true

### MIDI Interface
midi = MIDIator::Interface.new
midi.autodetect_driver

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

midi.instruct_user!

main_thread = Thread.new {loop {ip.add gets.chomp}} # get input from user

main_thread.join
NA::CL.threads.entries.each{|e|e.join}