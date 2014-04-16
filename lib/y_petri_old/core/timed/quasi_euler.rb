# encoding: utf-8

# Adaptation of Euler method for the systems possibly with timeless transitions
# and assignment transitions. Unlike +pseudo_euler+, which fires every step,
# +quasi_euler+ fires every time tick. Not implemented yet.
# 
module YPetri::Core::Timed::QuasiEuler
  # Computes Δ for the period of Δt. Not mplemented yet.
  # 
  def delta Δt
    fail NotImplementedError, "QuasiEuler not implemented yet!"
  end


  # Makes a single step by Δt. Not implemented yet.
  # 
  def step! Δt=simulation.step_size
    fail NotImplementedError, "QuasiEuler not implemented yet!"
    # Now one would have to compare whichever comes first, time tick or the
    # end of Δt, and then again and again, until Δt is fired...
  end
end # YPetri::Core::Timed::QuasiEuler
