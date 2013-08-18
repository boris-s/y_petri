# encoding: utf-8

# Plain Gillespie algorithm.
#
# The characteristic of the Gillespie method is, that it does not work starting
# from Δt towards Δstate. Instead, it makes a random choice weighted by the
# transition propensities, and the random choice determines both the next timed
# transition to fire, and the size of Δt to slice off from the time axis.
# 
module YPetri::Core::Timed::Gillespie
  # Name of this method.
  # 
  def simulation_method
    :gillespie
  end

  # Computes Δ for the period of Δt.
  # 
  def delta_time
    puts "Hello from Gillespie #delta_time !"
    pv_TS = propensity_vector_TS
    puts "Propensity vector tS is:"
    Kernel::p pv_TS
    puts "of #{pv_TS.class} class"
    total_rate = Σ pv_TS
    mean_period = 1 / total_rate
    # gradient * Δt
  end
  alias Δ delta
end # YPetri::Core::Timed::Euler
