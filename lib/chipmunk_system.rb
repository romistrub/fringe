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

require './chipmunk_extend'
require './chipmunk_draw'

module CP
  
  ## Scene-expectant wrapper for CP::Space
  class System < CP::Space
    
    attr_accessor :scene
    
    def initialize
      super
      @scene = nil  ## will contain reference to CP::Scene object  
    end
    
    ## Shortcut method to scene parameters; e.g. mouse_vector = p:mouse 
    def p(parameter)
      @scene.p parameter rescue nil
    end
    
    def to_scene(options={})
      CP::Scene.new(self, options)
    end
  
    ## Use CP::System objects to interact with CP::Scene by looking up method in scene object
    def method_missing(id, *args, &block)
      @scene.methods[id]
    end
  
  end
  
  ## CP::Scene is designed to draw a CP::System
  class Scene < Gosu::Window
  include CP::DrawGL
    
    def initialize(system, options={})
      
      ## DEFAULT OPTIONS
      options[:xy]    ||= [641, 481]    ## window size (width x height)
      options[:title] ||= ""            ## window caption
      options[:steps] ||= 3             ## chipmunk steps per gosu window update
        
      super (options[:xy][0], options[:xy][1], false)
      
      ## BIND SYSTEM AND SCENE
      @system = system
      @system.scene = self
      
      ## INSTANCE VARS
      @steps = options[:steps]
      @controls = {}

      ## GOSU VARIABLES
      caption = options[:title]
 
      ## DEFAULT HUMAN INTERFACE
        
      ## Retrieve vector direction from arrows
      add_parameter (:bearing) {|w|
        x,y = 0,0
        y += 1 if w.button_down?(Gosu::KbUp)
        y -= 1 if w.button_down?(Gosu::KbDown)
        x += 1 if w.button_down?(Gosu::KbRight)
        x -= 1 if w.button_down?(Gosu::KbLeft)
        cpv(x,y)
      }
      
      ## Converts absolute mouse position (in Gosu) to mouse position for Chipmunk
      add_parameter (:mouse) {|w|
        cpv(w.mouse_x - w.width/2, w.mouse_y - w.height/2)
      }
      
      add_listener (Gosu::KbEscape) {|w| w.close}
    
    end

      
    #### Drawing Logic ####
    
    ## time in milliseconds to increment space by for each step
    def dt
      (1.0/60.0)/@steps
    end
    
    ## Step I of automatic Gosu loop    
    def update
      @steps.times {@system.step(dt)}
    end
    
    ## Step II of automatic Gosu loop
    def draw
      clip_to(0, 0, width, height) do ## limits drawing area to the rectangle given
        draw_rect(0, 0, width, height, Gosu::white) ## draws background
        gl {gl_init; @system.draw;}  ## executes draw cascade in a clean GL environment
      end
    end
    
    #### Controller Logic ####
    
    ## Button Capture (mouse and keyboard)
    def button_down(id)
      @listeners[id].call self
    end

    def add_listener(*ids, &f)
    ids.each {|id| @listeners[id] = f}
    end
        
    def add_parameter(name, &f)
      @parameters[name.to_sym] = f
    end    
    
    def p(name)
      @parameters[name.to_sym].call self
    end
    
  end
end