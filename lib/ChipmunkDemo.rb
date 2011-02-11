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

require 'gosu'
require 'chipmunk_adjust'
require 'chipmunk_object'
require 'draw_gl'

require 'PyramidStack'
require 'Plink'
require 'Bounce'
require 'Tumble'
require 'PyramidTopple'
require 'LogoSmash'
require 'WalkBot'
require 'TheoJansen'
require 'Pump'
require 'PinballPaddle'

module ChipmunkDemos
  DEMOS = [
    LogoSmash::LogoSmashDemo,
    PyramidStack::PyramidStackDemo,
    Plink::PlinkDemo,
    Tumble::TumbleDemo,
    PyramidTopple::PyramidToppleDemo,
    Bounce::BounceDemo,
    WalkBot::WalkBotDemo,
    TheoJansen::TheoJansenDemo,
    Pump::PumpDemo,
    PinballPaddle::PinballPaddleDemo
  ]
  
  class MainWindow < Gosu::Window
    include CP::DrawGL
    def initialize
      super(641,481,false)
      @demo = DEMOS[0].new
      self.caption = "Chipmunk Demos: #{@demo.options[:title]}"
    end
    
    def update
      self.set_arrow_direction
      @demo.update
    end
    
    def draw
      self.clip_to(0,0,self.width,self.height) do 
        self.draw_rect(0,0,self.width,self.height,Gosu::white)
        self.gl do
          gl_init
          @demo.chipmunk_objects.each {|obj| obj.draw(self)}
        end
      end
    end
    
    def options
      @demo.options
    end
    
    def button_down(id)
      if id == Gosu::KbEscape
        close
      #elsif id == Gosu::MsLeft
      #  self.mouse_clicked
      elsif (demo = DEMOS[(self.button_id_to_char(id).ord - 'a'.ord)] rescue nil)
        @demo = demo.new
        self.caption = "Chipmunk Demos: #{@demo.options[:title]}"
      end
    end
    
    def draw_rect(x,y,w,h,c)
      self.draw_quad(x,y,c,x+w,y,c,x,y+h,c,x+w,y+h,c)
    end
    
    def mouse_clicked
      x,y = self.mouse_x,self.mouse_y
      loc = self.gosu_to_chipmunk(x,y)
      # No shape_point_query right now in the ruby binding. Something else
      # for now.
      #@demo.space.
    end
    
    def set_arrow_direction
      x,y = 0,0
      y += 1 if self.button_down?(Gosu::KbUp)
      y -= 1 if self.button_down?(Gosu::KbDown)
      x += 1 if self.button_down?(Gosu::KbRight)
      x -= 1 if self.button_down?(Gosu::KbLeft)
      
      @demo.arrow_direction = cpv(x,y)
    end
    
    def gosu_to_chipmunk(x,y)
      result = cpv(x-self.width/2,self.height/2)
    end
    
    def centerx
      0
    end
    
    def centery
      0
    end
  end
end

ChipmunkDemos::MainWindow.new.show
