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
    puts "Hello from Core::Timed#step!"
    assignment_transitions_all_fire!
    increment_marking_vector Δ( Δt )
    simulation.increment_time! Δt
    alert
  end
end # YPetri::Core::Timed::PseudoEuler
