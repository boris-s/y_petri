# encoding: utf-8

# A timeless simulation method class.
# 
module YPetri::Simulation::Timeless
  class Method < YPetri::Simulation::Method
    require_relative 'method/pseudo_euler.rb'

    alias delta delta_timeless
    alias Δ delta

    def step!
      super
      note_state_change
    end
  end
end
