# encoding: utf-8

# Timed simulation core. Knows several simulation methods applicable to
# timed nets.
# 
class YPetri::Core::Timed
  ★ YPetri::Core

  require_relative 'timed/basic'
  require_relative 'timed/ticked'
  require_relative 'timed/euler'
  require_relative 'timed/runge_kutta'
  require_relative 'timed/gillespie'

  METHODS = {
    basic: Basic,   # simple PN execution, timeless tt fire after each step
    ticked: Ticked, # like basic, but timeless tt fire at every time tick
    euler: Euler,               # for timed nets only
    runge_kutta: RungeKutta,    # for timed nets only
    gillespie: Gillespie        # for timed nets only
  }

  # This inquirer (=Boolean selector) is always true for timed cores.
  # 
  def timed?; true end

  # This inquirer (=Boolean selector) is always false for timed cores.
  # 
  def timeless?; false end

  def initialize **named_args
    super                       # TODO: Net type checking.
    extend METHODS.fetch simulation_method
    @delta_s = simulation.MarkingVector.zero( @free_pp )
    @delta_S = simulation.MarkingVector.zero( @free_pp )
  end

  # Makes a single step by Δt.
  # 
  def step! Δt=simulation.step
    increment_marking_vector Δ( Δt )
    simulation.increment_time! Δt
    simulation.recorder.alert
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
    # this could be
    # @Ts_gradient_closure.call
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
    fail msg unless Ts_transitions().empty?
    simulation.TS_rate_closure.call
  end

  # Flux vector of TS transitions.
  # 
  def flux_vector_TS
    simulation.TS_rate_closure.call
  end
  alias propensity_vector_TS flux_vector_TS
end # module YPetri::Core::Timed

# Textbook simulation methods ODE systems have many good simulation methods available.
#
# (1) mv' = ϝ f(mv, t).dt, where f(m, t) is a known function.
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

# In general, it is not required that all net nodes are simulated with the same method.
