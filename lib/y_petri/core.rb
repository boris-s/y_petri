# encoding: utf-8

require_relative 'core/timed'
require_relative 'core/timeless'

# This module represents a simulation core (execution machine), which can be
# either timed (class Core::Timed) or timeless (class Core::Timeless).
# 
module YPetri::Core
  ★ YPetri::Simulation::Dependency # it's beautiful to depend, and
  # comfortable to boot I wouldn't survive this refactoring if I try
  # to make it too right atm and duplicate everything the simulation
  # already has...

  DEFAULT_METHOD = :basic

  # I'm doing it this way in order to gradually begin decoupling in my mind
  # core from simulation. The constructed core will have to be assigned the
  # simulation object on which it will depend before core is made completely
  # independend on simulation. (Not gonna happen any soon.)
  # 
  attr_reader :simulation         # just a remark:
  attr_reader :simulation_method  # "reader" is "selector" in Landin's language

  def initialize simulation: nil, method: nil, guarded: false, **named_args
    @simulation = simulation or fail ArgumentError, "Core requires simulation!"
    @simulation_method = method || DEFAULT_METHOD
    
    if guarded then            # TODO: Guarded is unfinished business.
      fail NotImplementedMethod, "Guarded core is not implemented yet!"
      require_relative 'core/guarded' # TODO: Should be replaced with autoload.
    else @guarded = false end
    
    # Dependent on Simulation, this machine returns "delta contribution for ts
    # (timeless nonstoichiometric) transitions", which smells like a vector of
    # size corresponding to the number of free places.
    # 
    @delta_closure_for_ts_transitions = simulation.ts_delta_closure

    # This one is slightly different in that it returns so-called "firing vector",
    # from which delta vector is computed by multiplying it with tS stoichiometry
    # matrix.
    # 
    @firing_closure_for_tS_transitions = simulation.tS_firing_closure

    # This machine is special in that it directly modifies the marking vector,
    # firing the assignment transitions one by one (or so I think).
    # 
    @assignment_closure_for_A_transitions = simulation.A_direct_assignment_closure

    # We're gonna change all of the above. The marking vectors will be owned by
    # the core now. Machines will be wired only inside the core.
  end

  # TODO: this delegation below is not completely right.
  # 1. There is no subclassing and Timed/Timeless module inclusion, so there
  # is no need to delegate timed?/timeless? to the class, if only the modules
  # provide those inquirer methods (predicates in Landin's language).
  # 2. Same goes for guarded? predicate, which might be the business of
  # Core::Guarded module (or not)
  # 
  delegate :timed?,
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
    @delta_closure_for_ts_transitions.call
  end

  # Firing vector of tS transitions.
  # 
  def firing_vector_tS
    @firing_closure_for_tS_transitions.call
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

  # Fires all the assignment transitions.
  # 
  def fire_all_assignment_transitions!
    @assignment_closure_for_A_transitions.call
  end
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

