# encoding: utf-8

# This module represents a simulation core (execution machine), which can be
# either timed (class Core::Timed) or timeless (class Core::Timeless).
# 
module YPetri::Core
  ★ YPetri::Simulation::Dependency # dependency stays for now

  require_relative 'core/timed'
  require_relative 'core/timeless'

  DEFAULT_METHOD = :basic

  # Instead of getting the parametrized subclass of Timed/Timeless core
  # belonging to a simulation, I am passing a simulation instance to the
  # constructor now in order to gradually begin decoupling in my mind core
  # simulation. If I ever make the core independent from the simulation,
  # it will have its own representation of the net and its own capability
  # to form wiring and apply the required numerical procedures.

  attr_reader :simulation         # just a remark:
  attr_reader :simulation_method  # "reader" is "selector" in Landin's language
  attr_reader :guarded
  alias guarded? guarded

  attr_reader :free_pp,
              :clamped_pp,
              :pp,
              :marking_of_free_places,
              :marking_of_clamped_places

  def initialize simulation: nil, method: nil, guarded: false, **named_args
    @simulation = simulation or fail ArgumentError, "Core requires simulation!"
    @simulation_method = method || DEFAULT_METHOD

    if guarded then            # TODO: Guarded is unfinished business.
      fail NotImplementedMethod, "Guarded core is not implemented yet!"
      require_relative 'core/guarded' # TODO: Should be replaced with autoload.
    else @guarded = false end

    @free_pp = simulation.free_pp
    @clamped_pp = simulation.clamped_pp
    @pp = simulation.pp
    # TODO: Try to make the lines below simpler. In particular, in the future, core should
    # not depend on simulation at this level.
    @marking_of_free_places = simulation.MarkingVector.starting( @free_pp )
    @marking_of_clamped_places = simulation.MarkingVector.starting( @clamped_pp )

    # TODO: I don't remember how to load this in a simple way.
    simulation.state.to_hash.each do |place, value|
      if @marking_of_free_places.annotation.include? place then
        @marking_of_free_places.set( place, value )
      elsif @marking_of_clamped_places.annotation.include? place then
        @marking_of_clamped_places.set( place, value )
      else
        fail "Problem loading marking vector to timed core."
      end
    end
  end

  # Selector of the core's own state vector.
  #
  def state
    # TODO: Make it more efficient. Later, when core is detached from
    # simulation, use own assets instead of simulation.MarkingVector
    simulation.MarkingVector.zero.tap do |mv|
      @marking_of_free_places.annotation.each do |place|
        mv.set place, @marking_of_free_places.fetch( place )
      end
      @marking_of_clamped_places.annotation.each do |place|
        mv.set place, @marking_of_clamped_places.fetch( place )
      end
    end
  end

  delegate :alert!, to: :recorder

  # Delta contribution to free places by timeless transitions.
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
    # @delta_closure_for_ts_transitions.call
  end

  # Firing vector of tS transitions.
  # 
  def firing_vector_tS
    simulation.tS_firing_closure.call
    # @firing_closure_for_tS_transitions.call
  end

  # Increments the marking vector by a given delta.
  # 
  def increment_marking_vector( delta )
    print '.'
    # TODO: From now on, this won't touch the simulation's property
    # at all. It will be left to the simulation to ask for the results,
    # or to rig the core to message back when done.
    simulation.increment_marking_vector_closure.( delta )
  end

  # For now, alias method for #increment_marking_vector.
  # TODO: I already said to myself that I want the core not to rely
  # on the simulation's increment_marking_vector_closure.
  #
  def increment_free_vector( by: fail( "No delta given!" ) )
    print '.'
    simulation.increment_marking_vector_closure.( by )
    # Also, here it is not clear that #increment_marking_vector_closure
    # returns a closure that expects only Δ for free places. Should have
    # better mnemonic name.
  end

  # Fires all the assignment transitions.
  # 
  def fire_all_assignment_transitions!
    simulation.A_direct_assignment_closure.call
    # @assignment_closure_for_A_transitions.call
  end
  alias assignment_transitions_all_fire! fire_all_assignment_transitions!
end # module YPetri::Core

# TODO: Decouple Core and Simulation classes. It still looks like one
# simulation will use only one core (or one for each type of simulation
# trick), but I don't want the core to be parametrized by a Simulation
# instance. There should be at least a hint of core recruitment, sending
# the state to the core, asking the core to perform its trick on it, and
# asking back the results (or rigging the core to send them back as soon
# as done). A core should be more or less a one-trick pony. But simulation
# should also avoid doing too much, because above it, other classes (Agent
# and co.) may exist, doing things like optimization, parameter inferences
# aso.

# TODO: Regarding guarded cores, many kinds of PNs prohibit places from
# acquiring negative marking, or impose other restrictions. If the system
# state somehow makes it out of this safe envelope, the transitions may
# start behaving unpredictably. So there is a question of who is responsible
# for keeping the system sane (in the safe state envelope). The simple thing
# is for the core not to test anything and leave it up to the user not to
# define systems that are not sane. Simple is good, but there must be agreement,
# a requirement that the system specification behaves. If there is no such
# agreement, the core has no excuse from the need to guard against transitions
# trying to fire when they should properly be disabled (at least not if the
# core knows that the PN in question is classical). I did not decide what exactly
# should happen if the sanity is broken (raise an error? warn and try minor
# repair measures yourself?), but something should.
#
# Another example, in chemical systems, negative markings (concentrations)
# also ordinarily make no sense. But insensitive combination of functions
# and simulation method may lead to unsafe state with relatively late detection
# of error, leaving the modeller wondering when exactly the system state went
# haywire. Again, I'm not sure how exactly should the guarded core react to
# the treat of insane situation, but it somehow should.
#
# I feel it is necessary for the core to have awareness of the quality of
# the momentary system's state (at least to be able to tell whether it's
# meaningful at all), because later I want to let the core choose between
# deterministic (continous) and stochastic (discrete, going quantum by
# quantum, or by several quanta, there is more than one stochastic discrete
# method in stock) methods for simulation of individual processes.
