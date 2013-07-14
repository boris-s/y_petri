# encoding: utf-8

# A timed simulation method class.
# 
module YPetri::Simulation::Timed
  class Method < YPetri::Simulation::Method
    require_relative 'method/euler.rb'
    require_relative 'method/pseudo_euler.rb' # timeless fire after each step
    require_relative 'method/quasi_euler.rb'  # timeless fire each time tick

    # Makes a single step by Δt.
    # 
    def step! Δt=simulation.step_size
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
  end
end
