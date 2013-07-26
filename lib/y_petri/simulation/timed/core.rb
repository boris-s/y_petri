# encoding: utf-8

# A timed simulation method class.
# 
module YPetri::Simulation::Timed
  class Core < YPetri::Simulation::Core
    require_relative 'core/euler.rb'
    require_relative 'core/pseudo_euler.rb' # timeless fire after each step
    require_relative 'core/quasi_euler.rb'  # timeless fire each time tick

    # Makes a single step by Δt.
    # 
    def step! Δt=simulation.step
      increment_marking_vector Δ( Δt )
      increment_time! Δt
      note_state_change
    end

    # Gradient for free places.
    # 
    def gradient
      gradient_Ts + gradient_TS
    end
    alias ∇ gradient

    # Gradient contribution by Ts transitions.
    # 
    def gradient_Ts
      simulation.Ts_gradient_closure.call
    end

    # Gradient contribution by TS transitions.
    # 
    def gradient_TS
      ( simulation.TS_stoichiometry_matrix * flux_vector_TS )
    end

    # Flux vector. The caller asserts that all the timed transitions are
    # stoichiometric, or error.
    # 
    def flux_vector
      msg = "#flux_vector method only applies to the timed simulations with " +
        "no Ts transitions. Try #flux_vector_TS instead!"
      fail msg unless simulation.Ts_transitions.empty?
      simulation.TS_rate_closure.call
    end

    # Flux vector of TS transitions.
    # 
    def flux_vector_TS
      simulation.TS_rate_closure.call
    end
  end # class Core
end # module YPetri::Simulation::Timed

# In general, it is not required that all net elements are simulated with the
# same method. Practically, ODE systems have many good simulation methods
# available.
#
# (1) ᴍ(t) = ϝ f(ᴍ, t).dt, where f(ᴍ, t) is a known function.
#
# Many of these methods depend on the Jacobian, but that may not be available
# for some places. Therefore, the places, whose marking defines the system
# state, are divided into two categories: "A" (accelerated), for which as
# common Jacobian can be found, and "E" places, where "E" can stand either for
# "External" or "Euler".
#
# If we apply the definition of "causal orientation" on A and E places, then it
# can be said, that only the transitions causally oriented towards "A" places
# are allowed for compliance with the equation (1).
