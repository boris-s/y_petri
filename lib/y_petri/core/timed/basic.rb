# encoding: utf-8

# Basic Petri net execution method for timed and hybrid nets. Works also for
# timeless nets, but for those, Core::Timeless::Basic is slightly more efficient.
# 
module YPetri::Core::Timed::Basic
  # Computes Δ for the period of Δt. Its result is a sum of the contribution of
  # timed transitions over the period Δt and the contribution of timeless
  # transitions as if each fired once.
  # 
  def delta Δt
    gradient * Δt + delta_timeless
  end
  alias Δ delta

  # Makes a single step by Δt. Computes system delta, increments marking vector
  # by it. On top of that, fires all A transitions, increments the simulation
  # time and alerts the sampler that the system has changed.
  # 
  def step! Δt=simulation.step
    increment_marking_vector Δ( Δt )
    assignment_transitions_all_fire!
    simulation.increment_time! Δt
    alert! # alerts the sampler that the system has changed
  end
end # YPetri::Core::Timed::Basic
