# encoding: utf-8

# This class represents a simulator.
# 
class YPetri::Core
  # TODO: currently, Core and Simulation classes are tightly coupled.
  # each simulation has just one core, and that core looks directly
  # into the simulation's state. What needs to be done is a simulation
  # that at least hints the process of core recruitment for the requested
  # operation (be it step, step backwards, run forward aso.) and then
  # imprints the core with its current marking vector, tells the core
  # what to do, and then reads the result and updates its marking vector
  # accordingly. There are multiple possibilities, such as constructing
  # a new core for each operation, or keeping the same core for all the
  # operations using a given method. A simulation method (like euler,
  # gillespie, or runge-kutta) should be associated not so much with
  # the simulation object, as it should be associated with the core
  # object. A core object should be more or less one-trick pony. While
  # later, it is possible for a simulation to have broader simulation
  # strategy, or "method" in the broader sense. But simulation should
  # also avoid doing too much, because above it, there is Agent class,
  # and this class can be taught to do the more complicated things
  # such as parameter optimization or computation of control coefficients
  # and such. It is also possible to construct more specialized agent-like
  # classes for these more specialized tasks, since the main purpose
  # of Agent class, as I saw it, was to represent the user (represent
  # what the user means), to provide the user interface.
  
  require_relative 'core/timed'
  require_relative 'core/timeless'
  require_relative 'core/guarded'

  ★ YPetri::Simulation::Dependency

  DEFAULT_METHOD = :pseudo_euler

  class << self
    # Timed subclass of self.
    # 
    def timed
      Class.new self do
        include Timed
        def timed?; true end
        def timeless?; false end
      end
    end

    # Timeless subclass of self.
    # 
    def timeless
      Class.new self do
        include Timeless
        def timed?; false end
        def timeless?; true end
      end
    end

    # Vanilla simulator is not guarded.
    # 
    def guarded?; false end

    # Guarded subclass of self (not working yet).
    # 
    def guarded
      Class.new self do
        include Guarded
        def guarded?; true end
      end
    end
  end

  attr_reader :simulation_method

  def initialize method: nil, guarded: false, **named_args
    @simulation_method = method || DEFAULT_METHOD
    method_init # defined in Timed::Methods and Timeless::Methods
  end

  delegate :simulation,
           :timed?,
           :timeless?,
           :guarded?,
           to: "self.class"

  delegate :alert!,
           to: :recorder

  # Delta for free places from timeless transitions.
  # 
  def delta_timeless
    delta_ts + delta_tS
  end
  alias delta_t delta_timeless

  # Delta contribution by tS transitions.
  # 
  def delta_tS
    simulation.tS_stoichiometry_matrix * firing_vector_tS
  end

  # Delta contribution by ts transitions.
  # 
  def delta_ts
    simulation.ts_delta_closure.call
  end

  # Firing vector of tS transitions.
  # 
  def firing_vector_tS
    simulation.tS_firing_closure.call
  end

  # Increments the marking vector by a given delta.
  # 
  def increment_marking_vector( delta )
    print '.'
    simulation.increment_marking_vector_closure.( delta )
  end

  # Fires assignment transitions.
  # 
  def assignment_transitions_all_fire!
    simulation.A_direct_assignment_closure.call
  end
end # class YPetri::Core
