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

  # Makes a stochastic number of Gillespie steps necessary to span the period Δt.
  # 
  def step! Δt=simulation.step
    @gillespie_time = curr_time = simulation.time
    target_time = curr_time + Δt
    propensities = propensity_vector_TS
    puts "Propensity vector TS is:"
    Kernel::p propensities
    update_next_gillespie_time( propensities )
    until ( @next_gillespie_time > target_time )
      gillespie_step!
      note_state_change
      propensities = propensity_vector_TS
      update_next_gillespie_time( propensities )
    end
  end

  # Name of this method.
  # 
  def simulation_method
    :gillespie
  end

  # This method updates next firing time given propensities.
  # 
  def update_next_gillespie_time( propensities )
    @next_gillespie_time =
      @gillespie_time + gillespie_delta_time( propensities )
  end

  # Step.
  # 
  def gillespie_step! propensities
    t = choose_TS_transition( propensities )
    fire! t
  end

  # Computes Δ for the period of Δt.
  # 
  def gillespie_delta_time( propensities )
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
  def fire!( transition )
    transition.∇.map { |place, change|
      mv = simulation.marking_vector
      mv.set( place, mv.fetch( place ) + change )
    }
  end
end # YPetri::Core::Timed::Euler
