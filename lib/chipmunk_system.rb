#!/usr/bin/env ruby

require './Common.rb'
require './chipmunk_draw.rb'
require './chipmunk_extend2.rb'

module CP
  
  ## Scene-expectant wrapper for CP::Space
  class System < CP::Space
    @@threads = {}
    def self.threads() @@threads; end
      
    attr_accessor :scene, :dt
    
    def initialize(dt = 1.0/60)
      super()
      @scene = nil  ## will contain reference to CP::Scene object
      @dt = dt
    end
    
    def add_parameter(name, &f)
      @parameters[name.to_sym] = f
    end    
    
    def p(name)
      @parameters[name.to_sym].call self
    end
    
    def start
      if @thread && @thread.status == "sleep" then @thread.wake
      else
        @thread_id = Time.now.to_f
        @thread = RS::TimedLooper.new(dt, dt/10) {
          self.step(dt)
          self.update(@parameters)
        }
        @@threads[@thread_id] = @thread
      end
      self
    end
    
    def pause
      @thread.stop
    end
    
    def kill
      @thread.kill
      @@threads.delete @thread_id
    end
    
    def to_scene(options={})
      CP::Scene.new(self, options)
    end

  end
  
  ## CP::Scene is designed to draw a CP::System
  class Scene < Gosu::Window
  include CP::DrawGL
    
    def initialize(system, options={})
      
      ## DEFAULT OPTIONS
      options[:w]     ||= 641
      options[:h]     ||= 481           ## window size (width x height)
      options[:title] ||= ""            ## window caption
      options[:steps] ||= 3             ## chipmunk steps per gosu window update
        
      super(options[:w], options[:h], false)
      
      ## BIND SYSTEM AND SCENE
      @system = system
      @system.scene = self
      
      ## INSTANCE VARS
      @steps = options[:steps]
      @trackers = {}
      @listeners = {}

      ## GOSU VARIABLES
      @caption = options[:title]
 
      ## DEFAULT HUMAN INTERFACE
      add_tracker (:up)   {|w| w.button_down?(Gosu::KbUp)}
      add_tracker (:down)  {|w| w.button_down?(Gosu::KbDown)}
      add_tracker (:left) {|w| w.button_down?(Gosu::KbLeft)}
      add_tracker (:right) {|w| w.button_down?(Gosu::KbRight)}
      add_tracker (:mouse) {|w| [w.mouse_x - w.width/2, w.mouse_y - w.height/2]}
      add_listener (Gosu::KbEscape) {|w| w.close}
    
    end
      
    #### Drawing Logic ####
    
    ## Step I of automatic Gosu loop    
    def update()
    end
    
    ## Step II of automatic Gosu loop
    def draw
      clip_to(0, 0, width, height) { ## limits drawing area to the rectangle given
        draw_rect(0, 0, width, height, Gosu::white) ## draws background
        gl { ## executes draw cascade in a clean GL environment
          gl_init
          @system.draw(self);
        } 
      }
    end
    
    #### Controller Logic ####
    def button_down(id)         @listeners[id].call self if @listeners[id]; end
    def add_listener(*ids, &f)  ids.each {|id| @listeners[id] = f};         end
    def add_tracker(name, &f)   @trackers[name.to_sym] = f;                 end
    def get_tracker(name)       @trackers[name.to_sym];                     end
    def get_tracker_value(name) get_tracker(name).call self;                end
    def t(name)                 get_tracker_value(name);                    end
    
  end
end