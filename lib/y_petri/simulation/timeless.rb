# -*- coding: utf-8 -*-

# A mixin for timeless simulations.
# 
class YPetri::Simulation
  module Timeless
    require_relative 'timeless/recording'
    require_relative 'timeless/method'

    # False for timeless simulations.
    # 
    def timed?
      false
    end

    # Initialization subroutine.
    # 
    def init **nn
      @Recording = Class.new Recording
      @Method = Class.new Method
      tap do |sim|
        [ Recording(),
          Method()
        ].each { |ç| ç.class_exec { define_method :simulation do sim end } }
      end
    end
  end # module Timeless
end # module YPetri::Simulation
