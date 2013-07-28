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

  class << self
    alias __new__ new

    def new net: (fail ArgumentError, "No net supplied!"), **settings
      net.simulation **settings
    end
  end

  # Parametrized subclasses:
  attr_reader :core,
              :recorder,
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

  delegate :net, to: :class

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
  def initialize **settings
    method = settings[:method] # the simulation method
    @guarded = settings[:guarded] # guarding on / off
    m_clamps = settings[:marking_clamps] || {}
    init_m = settings[:initial_marking] || {}
    use_default_marking = settings[:use_default_marking] || true
    # Time-independent simulation settings received, constructing param. classes
    param_class( { Place: PlaceRepresentation,
                   Places: Places,
                   Transition: TransitionRepresentation,
                   Transitions: Transitions,
                   PlaceMapping: PlaceMapping,
                   InitialMarking: InitialMarking,
                   MarkingClamps: MarkingClamps,
                   MarkingVector: MarkingVector }, with: { simulation: self } )
    # Place and transition representation classes are their own namespaces.
    Place().namespace!
    Transition().namespace!
    # Set up the places collection.
    @places = Places().load( net.places )
    # Clamped places' mapping to the clamp values.
    @marking_clamps = MarkingClamps().load( m_clamps )
    # Free places' mapping to the initial marking values.
    @initial_marking = InitialMarking().load( init_m )
    # Set up the place and transition collections.
    @places.complete_initial_marking( use_default_marking: use_default_marking )
    # Correspondence matrix free --> all
    @f2a = free_places.correspondence_matrix( places )
    # Correspondence matrix clamped --> all
    @c2a = clamped_places.correspondence_matrix( places )
    # Conditionally extend self depending on net's timedness.
    extend( settings[:time] || settings[:step] || settings[:sampling] ?
            Timed : Timeless )
    # Initialize the marking vector.
    @m_vector = MarkingVector().zero
    # Set up the transitions collection.
    @transitions = Transitions().load( net.transitions )
    # Set up stoichiometry matrices relative to free places.
    @tS_stoichiometry_matrix = transitions.tS.stoichiometry_matrix
    @TS_stoichiometry_matrix = transitions.TS.stoichiometry_matrix
    # Set up stoichiometry matrices relative to all places.
    @tS_SM = transitions.tS.SM
    @TS_SM = transitions.TS.SM
    # Call timedness-dependent initialization.
    init **settings
    # Make timeless closures.
    @ts_delta_closure = transitions.ts.delta_closure
    @tS_firing_closure = transitions.tS.firing_closure
    @A_assignment_closure = transitions.A.assignment_closure
    @increment_marking_vector_closure = m_vector.increment_closure
    # Make timed closures.
    if timed? then
      @Ts_gradient_closure = transitions.Ts.gradient_closure
      @TS_rate_closure = transitions.TS.rate_closure
    end
    # Init the core.
    @core = Core().new( method: method, guarded: guarded  )
    # Reset.
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
      recorder.reset!
      recorder.alert
    end
  end

  # Guards proposed marking delta.
  # 
  def guard_Δ! Δ_free_places
    ary = ( marking_vector + F2A() * Δ_free_places ).column_to_a
    places.zip( ary ).each { |pl, proposed_m| pl.guard.( proposed_m ) }
  end

  # Extract a prescribed set of features.
  # 
  def get_features arg
    net.State.features( arg ).extract_from( self )
  end
end # class YPetri::Simulation
