# encoding: utf-8

# Plain Gillespie algorithm.
#
# The characteristic of the Gillespie method is, that it does not work starting
# from Δt towards Δstate. Instead, it makes a random choice weighted by the
# transition propensities, and the random choice determines both the next timed
# transition to fire, and the size of Δt to slice off from the time axis.
# 
module YPetri::Core::Timed::Gillespie
  attr_reader :rng

  # Gillespie method initialization.
  # 
  def initialize
    @rng = ::Random
  end

  # Name of this method.
  # 
  def simulation_method
    :gillespie
  end

  # Step.
  # 
  def step
    propensities = propensity_vector_TS
    puts "Propensity vector tS is:"
    Kernel::p propensities
    puts "of #{propensities.class} class"
    Δt = delta_time( propensities )
    t = choose_TS_transition( propensities )
  end

  # Computes Δ for the period of Δt.
  # 
  def delta_time( propensities )
    sum = Σ propensities
    mean_period = 1 / sum
    Distribution::Exponential.p_value( rng.rand, sum )
  end

  # Chooses the transition to fire.
  # 
  def choose_TS_transition( propensities )
    n = rng.rand
    propensities.index do |propensity|
      n -= propensity
      n <= 0
    end
  end

  # Fires a transition.
  # 
  def fire( transition )
    transition.∇.map { |place, change|
      mv = simulation.marking_vector
      mv.set( place, mv.fetch( place ) + change )
    }
  end
end # YPetri::Core::Timed::Euler
