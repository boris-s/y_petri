# encoding: utf-8

# Euler method with timeless transitions firing every time tick.
# 
module YPetri::Core::Timed::QuasiEuler
  include YPetri::Core::Timed::Euler

  # Name of this method.
  # 
  def simulation_method
    :quasi_euler
  end

  # Makes a single step by Δt.
  # 
  def step! Δt=simulation.step_size
    fail NotImplementedError
    # Now one would have to compare whichever comes first, time tick or the
    # end of Δt, and then again and again, until Δt is fired...
  end
end # YPetri::Core::Timed::QuasiEuler
