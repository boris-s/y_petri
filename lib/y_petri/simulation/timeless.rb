# encoding: utf-8

# A mixin for timeless simulations.
# 
class YPetri::Simulation
  module Timeless
    require_relative 'timeless/recording'
    require_relative 'timeless/core'

    # False for timeless simulations.
    # 
    def timed?
      false
    end

    # Initialization subroutine.
    # 
    def init **nn
      @Recording = Class.new Recording
      @Core = Class.new Core
      tap do |sim|
        [ Recording(),
          Core()
        ].each { |ç| ç.class_exec { define_method :simulation do sim end } }
      end

      @recording = Recording().new
    end
  end # module Timeless
end # module YPetri::Simulation
