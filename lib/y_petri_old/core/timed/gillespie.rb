# encoding: utf-8

# Plain Gillespie algorithm.
#
# The distinguishing quality of Gillespie method is, that it does not work from
# from Δt towards Δstate. Instead, it makes a random choice of the transition to
# fire (weighted by the transition propensities) and a random choice of Δt. Both
# next transition to fire, and the size of Δt to slice off from the time axis are
# thus stochastically determined.
# 
module YPetri::Core::Timed::Gillespie
  # Returns a random number generator, only created once.
  # 
  def rng
    @rng ||= ::Random
  end

  # Makes a stochastic number of Gillespie steps necessary to span the period Δt.
  # 
  def step! Δt=simulation.step
    @gillespie_time = curr_time = simulation.time
    target_time = curr_time + Δt
    propensities = propensity_vector_TS.column_to_a
    update_next_gillespie_time( propensities )
    until ( @next_gillespie_time > target_time )
      gillespie_step! propensities
      simulation.recorder.alert!
      propensities = propensity_vector_TS.column_to_a
      update_next_gillespie_time( propensities )
    end
    simulation.increment_time! Δt
    print '.'
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
    # mean_period = 1 / sum # TODO: This line seem to be useless
    # Exponential distribution
    Distribution::Exponential.p_value( rng.rand, sum )
  end

  # Given a discrete probability distributions, this function makes a random
  # choice of a category.
  # 
  def choose_from_discrete_distribution( distribution )
    sum = rng.rand * distribution.reduce( :+ )
    distribution.index do |p|
      sum -= p
      sum <= 0
    end
  end

  # Chooses the transition to fire.
  # 
  def choose_TS_transition( propensities )
    transitions.fetch choose_from_discrete_distribution( propensities )
  end

  # Fires a transitions. More precisely, performs a single transition event with
  # certain stoichiometry, adding / subtracting the number of quanta to / from
  # the codomain places as indicated by the stoichiometry.
  # 
  def fire!( transition )
    cd, sto = transition.codomain, transition.stoichiometry
    mv = simulation.m_vector
    cd.zip( sto ).each { |pl, coeff|
      mv.set( pl, mv.fetch( pl ) + pl.quantum * coeff )
    }
    @gillespie_time = @next_gillespie_time
  end
end # YPetri::Core::Timed::Euler
