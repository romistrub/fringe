Chipmunk Demos (Ruby)

This is a translation of Scott Lembke's Chipmunk Demos into Ruby, to as great
an extent as possible. Some of the demos could not be translated, as some
features of Chipmunk's C API are not yet exposed in the Ruby API.

To run these demos requires:

Ruby        >= 1.8.6, including 1.9.x
Gosu        >= 0.7.13.3* 
Ruby-OpenGL >= 0.60.1*
Chipmunk     = SVN-Trunk, or 0.5 (when it is released)

* earlier versions may work, but have not been tested.

Regarding the requirement of Chipmunk being SVN-Trunk, or 0.5 (which, at the
time of writing, has not yet been released): basically, if your version of
Chipmunk includes CP::Constraint and the chipmunk_ruby.rb file, it should
work. If it does not include those things, you need to upgrade.


To run the demos, just run `ruby ChipmunkDemo.rb`. If you used RubyGems to
install any of the requirements, and you are using ruby 1.8.x, then you'll
likely need to run `ruby -rubygems ChipmunkDemo.rb`

Once you're in the application, you can switch between demos by pressing the
letters 'a' through 'i' on the keyboard. In some demos, you can make things
happen by pressing the left or right arrow keys. Escape quits.

This code is copyright (c) 2009 Adam Gardner, and distributed under the MIT
license. See the file LICENSE.txt for details.


