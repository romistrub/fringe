require './Salt.rb'
require './Music.rb'

=begin
All machines have input and output. Everything in between is some sort of processor.
This machine translates a string of text from the console into MIDI messages.

TD DO
- Read from shared memory (e.g. a pipe in Linux)
- Only write machine activity logs to console
- MIDI matrix composition using layered affectors
=end


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