# encoding: utf-8

require_relative 'simulation/matrix'
require_relative 'simulation/dependency'
require_relative 'simulation/node_representation'
require_relative 'simulation/nodes'
require_relative 'simulation/nodes/access'
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
require_relative 'simulation/timeless'
require_relative 'simulation/timed'

# Represents a Petri net simulation. Its concerns include the simulation method,
# simulation settings, initial values, marking clamps used during the simulation,
# guards etc. Its concerns do not include the Petri net domain model as such
# (places, transitions, arcs, transition functions...)
# 
# In a simulation, some places are designated as free (ie. their marking is free
# to be changed by firing of the net's transitions), while others are clamped
# (their marking is clamped by the simulation rather than changed by the
# transitions). For free places, initial marking has to be specified. For
# clamped places, marking clamps have to be specified. (For convenience, places
# may carry their own initial marking.)
# 
class YPetri::Simulation
  ★ Places::Access                   # ★ means include
  ★ Transitions::Access
  ★ Nodes::Access
  ★ InitialMarking::Access
  ★ MarkingClamps::Access
  ★ MarkingVector::Access

  DEFAULT_SETTINGS = -> do { method: :basic, guarded: false } end

  class << self
    alias __new__ new

    def new net: (fail ArgumentError, "No net supplied!"), **settings
      net.simulation **settings
    end
  end

  # Parametrized subclasses.
  attr_reader :recorder, # :core,
              :guarded,
              :tS_stoichiometry_matrix,
              :TS_stoichiometry_matrix,
              :tS_SM,
              :TS_SM,
              :ts_delta_closure,
              :Ts_gradient_closure,
              :tS_firing_closure,
              :TS_rate_closure,
              :A_direct_assignment_closure,
              :increment_marking_vector_closure

  alias guarded? guarded

  delegate :net, to: "self.class"

  delegate :recording,
           :back!,
           to: :recorder

  delegate :simulation_method,
           :step!,
           :firing_vector_tS,
           to: :core

  alias r recording

  delegate :plot,
           :print,
           to: :recording

  # Returns the firing of the indicated tS transitions (all tS transitions,
  # if no argument is given).
  # 
  def firing ids_of_tS_transitions=nil
    tt = tS_transitions()
    return firing tt if ids_of_tS_transitions.nil?
    tS_transitions( ids_of_tS_transitions ).map { |t|
      firing_vector_tS.column_to_a.fetch tt.index( t )
    }
  end

  # Firing of the indicated tS transitions (as hash with transition names as
  # keys).
  #
  def t_firing ids=nil
    tS_transitions( ids ).names( true ) >> firing( ids )
  end

  # Pretty prints firing of the indicated tS transitions as hash with transition
  # names as keys. Takes optional list of tS transition ids (first ordered arg.),
  # and optional 2 named arguments (+:gap+ and +:precision+), as in
  # +#pretty_print_numeric_values+.
  # 
  def pfiring ids=nil, gap: 0, precision: 4
    t_firing( ids ).pretty_print_numeric_values( gap: gap, precision: precision )
  end

  # The basic simulation parameter is +:net+ – a collection of places and
  # transitions (a <tt>YPetri::Net</tt> instance) that is simulated. Other
  # required arguments are +:marking_clamps+ and +:initial_marking+
  # (or +:marking -- if no +:initial_marking+ is supplied, +:marking+ will be
  # used in its stead). Even when the caller did not provide all the
  # +:initial_marking+, there is an option of extracting them from the place
  # instances themselves. This option, controlled by the named argument
  # +use_default_marking+, is normally set to _true_, to turn it off, change
  # it to _false_.
  # 
  # Simulation method is set by +:method+ named argument, guarding is controlled
  # by +:guarded+ named argument (_true_/_false_). Simulations of timed nets are
  # also timed. For a timed simulation, the constructor permits named arguments
  # +:time+ (alias +:time_range+), +:step+ (simulation step size), and
  # +:sampling+ (sampling period), and requires that at least one of these named
  # arguments be supplied.
  # 
  def initialize use_default_marking: true,
                 guarded: false,
                 marking_clamps: {},
                 initial_marking: {},
                 marking: nil,
                 **settings
    param_class!( { PlacePS: PlaceRepresentation, # PS = parametrized subclass
                    PlacesPS: Places,
                    TransitionPS: TransitionRepresentation,
                    TransitionsPS: Transitions,
                    NodesPS: Nodes,
                    PlaceMapping: PlaceMapping,
                    InitialMarking: InitialMarking,
                    MarkingClamps: MarkingClamps,
                    MarkingVector: MarkingVector },
                  with: { simulation: self } )
    [ PlacePS(), TransitionPS() ].each &:namespace! # each serves as its namespace
    @guarded = guarded # TODO: Not operable as of now.
    @places = PlacesPS().load( net.places )
    @marking_clamps = MarkingClamps().load( marking_clamps )
    @initial_marking = if marking then
                         m = PlaceMapping().load( marking )
                         im = PlaceMapping().load( initial_marking )
                         InitialMarking().load( m.merge im )
                       else
                         InitialMarking().load( initial_marking )
                       end
    # Fill in the missing initial marking from the places' default marking.
    @places.send( :complete_initial_marking,
                  use_default_marking: use_default_marking )
    # Correspondence matrix free places --> all places
    @f2a = free_places.correspondence_matrix( places )
    # Correspondence matrix clamped places --> all places
    @c2a = clamped_places.correspondence_matrix( places )
    # Conditionally extend self depending on net's timedness.
    time_mentioned = settings[:time] || settings[:step] || settings[:sampling]
    if time_mentioned then extend Timed else extend Timeless end
    # Initialize the marking vector.
    @m_vector = MarkingVector().zero
    # Set up the collection of transitions.
    @transitions = TransitionsPS().load( net.transitions )
    # Set up stoichiometry matrices relative to free places.
    @tS_stoichiometry_matrix = transitions.tS.stoichiometry_matrix
    @TS_stoichiometry_matrix = transitions.TS.stoichiometry_matrix
    # Set up stoichiometry matrices relative to all places.
    @tS_SM = transitions.tS.SM
    @TS_SM = transitions.TS.SM
    # Call timedness-dependent #init subroutine.
    init **settings
    # Make time-independent closures.
    @ts_delta_closure = transitions.ts.delta_closure
    @tS_firing_closure = transitions.tS.firing_closure
    @A_direct_assignment_closure = transitions.A.direct_assignment_closure
    @increment_marking_vector_closure = m_vector.increment_closure
    # Make timed-only closures.
    if timed? then
      @Ts_gradient_closure = transitions.Ts.gradient_closure
      @TS_rate_closure = transitions.TS.rate_closure
    end
    # Reset.
    if marking then reset! marking: marking else reset! end
  end

  # Simulation settings.
  # 
  def settings all=false
    return { method: simulation_method, guarded: guarded? } unless all == true
    { net: net,
      marking_clamps: marking_clamps.keys_to_source_places,
      initial_marking: initial_markings.keys_to_source_places
    }.update( settings )
  end

  # Returns a new simulation instance. Unless modified by arguments, the state
  # of the new instance is the same as the creator's. Arguments can partially or
  # wholly modify the attributes of the duplicate.
  # 
  def dup( marking: marking, recording: recording, **named_args )
    named_args.reverse_merge! settings( true )
    self.class.new( named_args ).tap do |duplicate|
      duplicate.recorder.reset! recording: recording
      duplicate.m_vector.reset! case marking
                                when Hash then
                                  m_vector.to_hash_with_source_places
                                    .update( PlaceMapping().load( marking )
                                               .to_marking_vector
                                               .to_hash_with_source_places )
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

  # Resets the simulation.
  # 
  def reset! marking: nil, **named_args
    tap do
      marking ? m_vector.reset!( marking ) : m_vector.reset!
      recorder.reset!.alert!
    end
  end

  # Guards proposed marking delta.
  # 
  def guard_Δ! Δ_free_places
    ary = ( marking_vector + F2A() * Δ_free_places ).column_to_a
    places.zip( ary ).each { |pl, proposed_m| pl.guard.( proposed_m ) }
  end

  # TODO: The method below does nothing except that it delegates extraction
  # of a set of features to Features class. Features understood in this way
  # are similar to ZZ dimensions.

  # Extract a prescribed set of features.
  # 
  def get_features *args
    net.State.Features( *args ).extract_from( self )
  end
end # class YPetri::Simulation
