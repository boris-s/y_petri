#encoding: utf-8

require_relative 'simulation/matrix'
require_relative 'simulation/dependency'
require_relative 'simulation/element_representation'
require_relative 'simulation/elements'
require_relative 'simulation/elements/access'
require_relative 'simulation/place_representation'
require_relative 'simulation/places'
require_relative 'simulation/places/access'
require_relative 'simulation/transition_representation'
require_relative 'simulation/transitions'
require_relative 'simulation/transitions/access'
require_relative 'simulation/place_mapping'
require_relative 'simulation/marking_clamps'
require_relative 'simulation/marking_clamps/access'
require_relative 'simulation/initial_marking'
require_relative 'simulation/initial_marking/access'
require_relative 'simulation/marking_vector'
require_relative 'simulation/marking_vector/access'
require_relative 'simulation/recorder'
require_relative 'simulation/core'
require_relative 'simulation/timeless'
require_relative 'simulation/timed'

# Represents a Petri net simulation, concerning are the simulation method and
# settings, initial values, marking clamps, guards and similar. Its concerns are
# are separated from those of the Petri net domain model (existence, naming,
# connectivity, functions...). Clamps, guards, initial values etc. <b>do not
# belong</b> to the model, although for convenience, places may carry default
# initial marking, guards, and clamps for use in the token game. Simulation
# instance can also use these if none other are specified.
# 
# A simulation distinguishes between free and clamped places. For free places,
# initial marking has to be specified. For clamped places, marking clamps have
# to be specified. Both come as hashes:
# 
class YPetri::Simulation
  include Places::Access
  include Transitions::Access
  include Elements::Access
  include InitialMarking::Access
  include MarkingClamps::Access
  include MarkingVector::Access

  DEFAULT_SETTINGS = -> do { method: :pseudo_euler, guarded: false } end

  # Parametrized subclasses:
  attr_reader :net,
              :core,
              :guarded,
              :tS_stoichiometry_matrix,
              :TS_stoichiometry_matrix,
              :tS_SM,
              :TS_SM,
              :ts_delta_closure,
              :Ts_gradient_closure,
              :tS_firing_closure,
              :TS_rate_closure,
              :A_assignment_closure,
              :increment_marking_vector_closure

  alias guarded? guarded

  delegate :method,
           :guarded?,
           :step!,
           to: :core

  delegate :recording,
           to: :recorder

  # The basic simulation parameter is :net – +YPetri::Net+ instance which to
  # simulate. Net implies the collection of places and transitions. Other
  # required attributes are marking clamps and initial marking. These can be
  # extracted from the Place and Transition instances if not given explicitly.
  # Simulation method is controlled by the :method argument, guarding is
  # switched on and off by the :guarded argument (true/false). If timed
  # transitions are present, the simulation is considered timed. Timed
  # simulation constructor has additional arguments :time, establishing time
  # range, :step, controlling the simulation step size, and :sampling,
  # controlling the sampling frequency.
  # 
  def initialize method: nil,        # the simulation method
                 guarded: false,     # whether the simulation is guarded
                 net: ( fail ArgumentError, "Net missing!" ),
                 marking_clamps: {},
                 initial_marking: {},
                 use_default_marking: true,
                 **nn

    @net = net
    @guarded = guarded
    init_element_representation
    @m_vector = MarkingVector().zero
    extend nn[:time] || nn[:step] || nn[:sampling] ? Timed : Timeless

    init_core_and_recorder_subclasses
    init_places( marking_clamps, initial_marking,
                 use_default_marking: use_default_marking )

    init_transitions
    init **nn # Timed / Timeless dependent initialization

    # Make timeless closures:
    @ts_delta_closure = transitions.ts.delta_closure
    @tS_firing_closure = transitions.tS.firing_closure
    @A_assignment_closure = transitions.A.assignment_closure
    @increment_marking_vector_closure = m_vector.increment_closure

    if timed? then # also make timed closures:
      @Ts_gradient_closure = transitions.Ts.gradient_closure
      @TS_rate_closure = transitions.TS.rate_closure
    end

    # Init the core.
    @core = Core().new( method: method, guarded: guarded  )

    reset!
  end

  # Simulation settings.
  # 
  def settings all=false
    return { method: method, guarded: guarded? } unless all == true
    settings( false )
      .update( net: net,
               marking_clamps: marking_clamps.keys_to_source_places,
               initial_marking: initial_marking.keys_to_source_places )
  end

  # Returns a new simulation instance. Unless modified by arguments, the state
  # of the new instance is the same as the creator's. Arguments can partially or
  # wholly modify the attributes of the duplicate.
  # 
  def dup( marking: marking, recording: recording, **nn )
    self.class.new( nn.reverse_merge! settings( true ) ).tap do |dup|
      dup.recording.reset! recording: recording
      dup.m_vector.reset! case marking
                          when Hash then
                            m_vector.to_hash_with_source_places
                              .update( PlaceMapping().load( marking ) )
                              .to_marking_vector
                          when Matrix, Array then marking
                          else marking.each.to_a end
    end
  end

  # Inspect string for this simulation.
  # 
  def inspect
    to_s
  end

  # String representation of this simulation.
  # 
  def to_s
    "#<Simulation: pp: %s, tt: %s, oid: %s>" % [ pp.size, tt.size, object_id ]
  end

  # Resets the simulation
  # 
  def reset!
    tap do
      m_vector.reset!
      recording.reset!
      recording.note_state_change
    end
  end

  # Guards proposed marking delta.
  # 
  def guard_Δ! Δ_free_places
    ary = ( marking_vector + F2A() * Δ_free_places ).column_to_a
    places.zip( ary ).each { |pl, proposed_m| pl.guard.( proposed_m ) }
  end

  private

  # Sets up parametrized subclasses representing elements / element collections.
  # 
  def init_element_representation
    param_class( { Place: PlaceRepresentation,
                   Transition: TransitionRepresentation,
                   Places: Places,
                   Transitions: Transitions,
                   PlaceMapping: PlaceMapping,
                   InitialMarking: InitialMarking,
                   MarkingClamps: MarkingClamps,
                   MarkingVector: MarkingVector },
                 with: { simulation: self } )
    Place().namespace!
    Transition().namespace!
  end

  # Sets up a representation of the net's places, clamps and initial marking.
  # 
  def init_places( marking_clamps, initial_marking, use_default_marking: true )
    # Seting up the place and transition collections.
    @places = Places().load( net.places )
    @marking_clamps = MarkingClamps().load( marking_clamps )
    @initial_marking = InitialMarking().load( initial_marking )
    @places.complete_initial_marking( use_default_marking: use_default_marking )
    # Correspondence matrices free --> all and clamped --> all:
    @f2a = free_places.correspondence_matrix( places )
    @c2a = clamped_places.correspondence_matrix( places )
  end

  # Sets up a representation of the net's transitions.
  # 
  def init_transitions
    @transitions = Transitions().load( net.transitions )
    # Stoichiometry matrices relative to free places:
    @tS_stoichiometry_matrix = transitions.tS.stoichiometry_matrix
    @TS_stoichiometry_matrix = transitions.TS.stoichiometry_matrix
    # Stoichiometry matrices relative to all places:
    @tS_SM = transitions.tS.SM
    @TS_SM = transitions.TS.SM
  end
end # class YPetri::Simulation
