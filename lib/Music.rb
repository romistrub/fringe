require 'midiator'
require './Math.rb'

=begin
TD DO
- Decompose human composition patterns into distinct time-dependent factors.
5xRAND-vector f(t) represents 5 fingers with no limitations to keyboard position or activity
P(t) centres on hand by condensing P x f(t) P transforms f by 

- Note position ~ Gauss-random(centre: hand position, std: hand width) * scale

- Scale ~ Gauss-random(c: current scale, std: eccentricity)
- Current scale ~ Gauss-random (c: starting scale, std: drift)

- Note on/velocity
- Note off/velocity
e.g. [60 0 75 0 0] translates into note on and off depending on previous state
- Finger pattern ~ Gauss-random(c: finger pattern, std: creativity) + finger flow * finger innervation

- Finger bias ~ Gauss-random(c: hand shape, std: contortion) [-3 -2 0 2 4]

- sparsity
- Finger innervation ~ Gauss-random(c: hand innervation, std: finger independence)

- Hand position ~ Gauss-random(centre: hand position, std: arm dance) + arm flow * arm innervation
- Arm flow ~ Gauss-random(centre: arm flow, std: instability) (upness and downness)
- Arm innervation ~ Gauss-random(centre: style, std: turbulence) (violence of arm movement)
- Style ~ Gauss-random(centre: starting style, std: range) (e.g. allegro)

- Human mind develops patterns and retains them over some period
- Use Gaussian random variables to seed the magnitude of changes
=end

# play: note, duration, channel, velocity
class MIDIator::Interface
include NA::CL::Output
  def from_atom(atom)
    puts "PLAY: " + atom.inspect
    Thread.new {self.play(atom[:note], atom[:duration], atom[:channel], atom[:velocity])}
  end
end

include MIDIator::Notes
include MIDIator::Scales