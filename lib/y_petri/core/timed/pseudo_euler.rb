# encoding: utf-8

# Euler method with timeless transitions firing after each step.
# 
class YPetri::Core::Timed
  module PseudoEuler
    include Euler

    # Name of this method.
    # 
    def simulation_method
      :pseudo_euler
    end

    # Computes Δ for the period of Δt.
    # 
    def delta Δt
      super + delta_timeless
    end
    alias Δ delta

    # Makes a single step by Δt.
    # 
    def step! Δt=simulation.step
      increment_marking_vector Δ( Δt )
      assignment_transitions_all_fire!
      simulation.increment_time! Δt
      alert
    end
  end # PseudoEuler
end # YPetri::Core::Timed
