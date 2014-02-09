# encoding: utf-8

# Euler method with timeless transitions firing after each step.
# 
module YPetri::Core::Timed::PseudoEuler
  include YPetri::Core::Timed::Euler

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
    alert!
  end
end # YPetri::Core::Timed::PseudoEuler
