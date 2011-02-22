require 'MIDIator'
require './Salt.rb'
include MIDIator::Notes
include MIDIator::Scales

# play: note, duration, channel, velocity
class MIDIator::Interface
include NA::CL::Output
  def from_atom(atom)
    play(atom[:note], atom[:duration], atom[:channel], atom[:velocity])
  end
end

ip=NA::CL::Input.new.
to NA::CL::Membrane.new{|atom|
# "hey how are you" --> ["hey" "how" "are" "you"]
  atom.split  #haha BOOM 
}.
to NA::CL::Vessel.new({period: 3}){|atom|
# "enoughschoolworkalreadymkay" --> ["en" "ough" "schoolw" "ork" "alr" "eady" "mkay"]
  atom.scan(/[^aeiouAEIOU]*[aeiouAEIOU]+[^aeiouAEIOU]{0,2}/)
}.
to NA::CL::Membrane.new{|atom|
# translator
  {
    channel:    1,
    note:       ((MAJOR .p C6) + (MINOR .p C7)).like(atom.bytes.entries ,#60-96, spanning three octaves
    duration:   atom.length,
    velocity:   atom.bytes.entries[0] #coincidentally a single byte (0-127), though most are useless
  }
}.
atom.chars.entries
to MIDIator::Interface.new

midi_interface = MIDIator::Interface.new
midi_interface.driver.instruct_user!

main_thread = Thread.new {
  loop {
    ip.add gets.chomp, gets.chomp
  }
}

main_thread.join

class Array
  def seek(dec) # accepts [0,1) (not including 1)
    fetch(size*dec.to_int)
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
  def avg
    
  end
  def sum
    
  end
end
