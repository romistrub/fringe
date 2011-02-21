require './Glassware.rb'

ip=NA::CL::Input.new.
to NA::CL::Membrane.new{|atom| atom+atom}.
to NA::CL::Outputter.new

main_thread = Thread.new {
  loop {ip.add gets.chomp, gets.chomp}
}

main_thread.join