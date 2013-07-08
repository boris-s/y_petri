#encoding: utf-8

require_relative 'simulation/dependency_injection'
require_relative 'simulation/place_representation'
require_relative 'simulation/place_representation/collections'
require_relative 'simulation/transition_representation'
require_relative 'simulation/transition_representation/collections'
require_relative 'simulation/elements'
require_relative 'simulation/places'
require_relative 'simulation/transitions'
require_relative 'simulation/marking_clamps'
require_relative 'simulation/initial_marking'

require_relative 'simulation/timed'

# Represents a simulation of a Petri net, using certain method and settings.
# Simulation concerns (simulation method and settings, initial values, marking
# clamps, guards...) are separated from those Petri net domain model (existence,
# naming, connectivity and function specification of the net). Clamps, guards,
# initial values etc. <b>do not belong</b> to the model, although for
# convenience, places may carry default initial marking, default guards, and
# default clamps for use in simulations if none other are specified.
# 
# A simulation distinguishes between free and clamped places. For free
# places, initial marking has to be specified. For clamped places, marking
# clamps have to be specified. Both come as hashes:
# 
class YPetri::Simulation
  include PlaceRepresentation::Collections
  include TransitionRepresentation::Collections

  SAMPLING_DECIMAL_PLACES = 5
  SIMULATION_METHODS =
    [
      [:pseudo_Euler] # pseudo-timed simulation (like in Cell Illustrator)
    ]
  DEFAULT_SIMULATION_METHOD = :pseudo_Euler

  class << ::Matrix
    # Builds a code string for accessing the vector values at given indices.
    # 
    def column_vector_access_code( vector: (fail ArgumentError, "No vector!"),
                                   indices: (fail ArgumentError, "No indices!") )
      indices.map { |i| "#{vector}[#{i}, 0]" }.join( ", " )
    end

    # Builds a code string for assigning to a vector at given indices.
    # 
    def column_vector_assignment_code vector: (fail ArgumentError, "No vector!"),
                                      indices: (fail ArgumentError, "No indices!"),
                                      source: (fail ArgumentError, "No source array!")
      indices.map.with_index do |i, source_pos|
        "#{vector}.send( :[]=, #{i}, 0, #{source}.fetch( #{source_pos} ) )" if i
      end.compact.join( "\n" ) << "\n"
    end
  end

  # Default simulation method (accesses the constant DEFAULT_SIMULATION_METHOD
  # in the receiver's class).
  # 
  def default_simulation_method
    self.class.const_get :DEFAULT_SIMULATION_METHOD
  end

  # Parametrized subclasses:
  attr_reader :Place, :Transition
  attr_reader :Places, :Transitions
  attr_reader :MarkingClamps, :InitialMarking

  # Overloaded reader of @places is defined in Places::Collections.
  # Overloaded reader of @transitions is defined in Transitions::Collections.

  attr_reader :method, :guarded
  alias guarded? guarded
  attr_reader :timed
  alias timed? timed
  attr_reader :net

  # Stoichiometry matrices.
  # 
  attr_reader :tS_stoichiometry_matrix, :TS_stoichiometry_matrix
  attr_reader :tS_SM, :TS_SM

  # Simulator machine
  #
  # maintain a marking vector
  # get the closures for its modification
  # call them as the simulation method dictates

  attr_reader :time_unit
  attr_reader :zero_∇, :zero_gradient
  attr_reader :recording

  attr_reader :ts_delta_closure
  attr_reader :Ts_gradient_closure
  attr_reader :tS_firing_closure
  attr_reader :TS_rate_closure
  attr_reader :A_assignment_closure

  # With no arguments, a reader of @f2a -- the correspondence matrix between
  # free places and all places. If argument is given, it is assumed to be
  # a column vector, and multiplication is performed.
  # 
  def f2a arg=nil
    if arg.nil? then @f2a else @f2a * arg end
  end

  # With no arguments, a reader of @c2a -- the correspondence matrix between
  # clamped places and all places. If argument is given, it is assumed to be
  # a column vector, and multiplication is performed.
  # 
  def c2a arg=nil
    if arg.nil? then @c2a else @c2a * arg end
  end

  # Simulation settings.
  # 
  def settings; {} end
  alias :simulation_settings :settings

  # Without arguments, returns all the elements (places + transitions). If
  # arguments are given, they are converted into elements.
  # 
  def elements *ids
    return places + transitions if ids.empty?
    ids.map { |id| element( id ) }
  end
  
  # Names of the simulation's elements. Arguments, if any, are treated
  # analogically to the +#elements+ method.
  # 
  def en *ids
    elements( *ids ).names
  end

  # Without arguments, acts as a getter of the @initial_marking hash. If
  # arguments are supplied, they must identify free places, and are mapped
  # to their initial marking.
  # 
  def initial_marking *ids
    if ids.empty? then
      @initial_marking or
        fail TypeError, "InitialMarking object not instantiated yet!"
    else
      free_places( *ids ).map { |pl| initial_marking of: pl }
    end
  end

  # Without arguments, returns the marking of all the simulation's places
  # (both free and clamped) as it appears after reset. If arguments are
  # supplied, they must identify places, and are converted to either their
  # initial marking (free places), or their clamp value (clamped places).
  # 
  def im *ids
    return im( *places ) if ids.empty?
    places( *ids ).map { |pl|
      pl.free? ? initial_marking( of: pl ) : marking_clamp( of: pl )
    }
  end

  # Returns initial marking vector for free places. Like +#initial_marking+,
  # but returns a column vector.
  # 
  def initial_marking_vector *ids
    initial_marking( *ids ).to_column_vector
  end

  # Returns initial marking vector for all places. Like +#initial_marking+,
  # but returns a column vector.
  # 
  def im_vector *ids
    im( *ids ).to_column_vector
  end

  # Place clamp definitions for clamped places (as array).
  # 
  def marking_clamps *ids
    if ids.empty? then
      @marking_clamps or
        fail TypeError, "MarkingClamps object not instantiated yet!"
    else
      clamped_places( *ids ).map { |pl| marking_clamp of: pl }
    end
  end
  alias clamps marking_clamps

  # Marking of free places (as array).
  # 
  def marking *ids
    return free_places.map( &:marking ) if ids.empty?
    free_places( *ids ).map { |pl| pl.marking }
  end

  # Marking vector of free places.
  # 
  def marking_vector *ids
    marking( *ids ).to_column_vector
  end
  
  # Marking of free places (as hash).
  # 
  def place_marking *ids
    free_places( *ids ) >> marking( *ids )
  end
  
  # Marking of free places (as { place.name => marking } hash).
  # 
  def pn_marking *ids
    free_places( *ids ).names( true ) >> marking( *ids )
  end
  
  # Marking of all places (as array)
  # 
  def m *ids
    return m( *places ) if ids.empty?
    places( *ids ).map &:marking
  end
  
  # Marking of all places (as a column vector)
  # 
  def m_vector *ids
    if ids.empty? then
      @m_vector or
        fail TypeError, "Marking vector not established yet!"
    else
      m( *ids ).to_column_vector
    end
  end

  # Marking of all places (as hash).
  # 
  def place_m *ids
    places( *ids ) >> m( *ids )
  end
  
  # Marking of all places (as { place.name => marking } hash).
  # 
  def pn_m *ids
    places( *ids ).names( true ) >> m( *ids )
  end
  alias pm pn_m

  # Required parameters are :net, :marking_clamps and :initial_marking. Optional
  # is :method (simulation method), and :guarded (true/false, whether the
  # simulation is guarded.)
  # 
  # In addition to the arguments required by the regular simulation
  # constructor, timed simulation constructor also expects :step_size
  # (alias :step), :sampling_period (alias :sampling), and :target_time
  # named arguments.
  # 
  def initialize( method: default_simulation_method,
                  guarded: false,
                  net: ( fail ArgumentError, ":net argument is compulsory!" ),
                  marking_clamps: {},
                  initial_marking: {},
                  use_default_marking: true,
                  time_unit: 1,
                  **nn )
    puts "constructing a simulation" if YPetri::DEBUG

    @method = method                         # simulation method
    @guarded = guarded                       # whether the simulation is guarded
    @time_unit = time_unit

    # Init the places
    init_places( net, marking_clamps, initial_marking,
                 use_default_marking: use_default_marking )

    # Reset the simulation (transition closures need it).
    @m_vector = zero_m_vector

    # Init the transitions
    init_transitions( net )
    
    # Other assets:
    @ts_delta_closure = transitions.ts.delta_closure
    @tS_firing_closure = transitions.tS.firing_closure
    @Ts_gradient_closure = transitions.Ts.gradient_closure
    @TS_flux_closure = transitions.TS.rate_closure
    @A_assignment_closure = transitions.A.assignment_closure
    puts "closures set up" if YPetri::DEBUG

    @timed = if nn.has?( :time ) || nn.has?( :step ) || nn.has?( :sampling )
               extend Timed
               true
             else false end

    if timed? then # we have to set up all the expected variables
      if nn[:time] then # time range given
        time_range = nn[:time]
        @initial_time, @target_time = time_range.begin, time_range.end
        @step_size = nn[:step] || target_time / target_time.to_f
        @sampling_period = nn[:sampling] || step_size
      else
        anything = nn[:step] || nn[:sampling]
        @initial_time, @target_time = anything * 0, anything * Float::INFINITY
        @step_size = nn[:step] || anything / anything.to_f
        @sampling_period = nn[:sampling] || step_size
      end
    end

    reset!
  end

  # Returns a new instance of the system simulation at a specified state, with
  # same simulation settings. This state (:marking argument) can be specified
  # either as marking vector for free or all places, marking array for free or
  # all places, or marking hash. If vector or array is given, its size must
  # correspond to the number of either free, or all places. If hash is given,
  # it is not necessary to specify marking of every place – marking of those
  # left out will be left same as in the current state.
  # 
  def at( marking: marking, **nn )
    err_msg = "Size of supplied marking must match either the number of " +
      "free places, or the number of all places!"
    update_method = case marking
                    when Hash then :update_marking_from_a_hash
                    when Matrix then
                      case marking.column_to_a.size
                      when places.size then :set_marking_vector
                      when free_places.size then :set_ᴍ
                      else fail TypeError, err_msg end
                    else # marking assumed to be an array
                      case marking.size
                      when places.size then :set_marking
                      when free_places.size then :set_m
                      else fail TypeError, err_msg end
                    end
    return dup( **nn ).send( update_method, marking )
  end

  # Produces the inspect string of the transition.
  # 
  def inspect
    "#<YPetri::Simulation: #{pp.size} pp, #{tt.size} tt, ID: #{object_id} >"
  end

  # Produces a string briefly describing the simulation instance.
  # 
  def to_s
    "Simulation[#{pp.size} pp, #{tt.size} tt]"
  end

  # Place instance identification.
  # 
  def place( id )
    begin
      Place().instance( id )
    rescue NameError, TypeError
      begin
        pl = net.place( id )
        places.find { |p_rep| p_rep.source == pl } ||
          Place().instance( pl.name )
      rescue NameError, TypeError => msg
        raise TypeError, "The argument #{id} does not identify a " +
          "place instance! (#{msg})"
      end
    end
  end
  
  # Transition instance identification.
  # 
  def transition( id )
    begin
      Transition().instance( id )
    rescue NameError, TypeError
      begin
        puts 'here'
        tr = net.transition( id )
        Transition().instances.find { |t_rep| t_rep.source == tr } || 
          Transition().instance( tr.name )
      rescue NameError, TypeError => msg
        raise TypeError, "The argument #{id} does not identify a " +
          "transition instance! (#{msg})"
      end
    end
  end
  
  # Does a place belong to the simulation?
  # 
  def includes_place?( id )
    true.tap { begin; place( id )
               rescue NameError, TypeError
                 return false
               end }
  end
  alias include_place? includes_place?
  
  # Does a transition belong to the simulation?
  # 
  def includes_transition?( id )
    true.tap { begin; transition( id )
               rescue NameError, TypeError
                 return false
               end }
  end
  alias include_transition? includes_transition?
  
  # Does an element belong to the simulation?
  # 
  def includes?( id )
    includes_place?( id ) || includes_transition?( id )
  end
  alias include? includes?
  
  # Element instance identification.
  # 
  def element( id )
    return place( id ) if includes_place?( id )
    return transition( id ) if includes_transition?( id )
    puts id.class.ancestors.join ', '
    puts id.name
    fail TypeError, "No element #{id} in the simulation!"
  end
  
  # Marking clamp identification.
  # 
  def marking_clamp( of: (fail ArgumentError) )
    marking_clamps.clamp_of( of )
  end
  
  # Initial marking object identification.
  # 
  def initial_marking( of: nil )
    return @initial_marking if not of
    initial_marking.of( of )
  end
  
  private

  # Resets the simulation
  # 
  def reset!
    set_m_vector( starting_m_vector )
    reset_recording!
    note_state_change!
    return self
  end

  # Resets the recording.
  # 
  def reset_recording!
    @recording = {}
  end

  # To be called whenever the state changes. The method will cogitate, whether
  # the observed state change warrants calling #sample!
  # 
  def note_state_change!
    sample! # default for vanilla Simulation: sample! at every occasion
  end
    
  # Performs sampling. A snapshot of the current simulation state is recorded
  # into @recording hash as a pair { sampling_event => simulation state }.
  # 
  def sample! key=L!(:sample!)
    @sample_number = @sample_number + 1 rescue 0
    @recording[ key.ℓ?(:sample!) ? @sample_number : key ] =
      marking.map { |n| n.round SAMPLING_DECIMAL_PLACES }
  end

  # Expects a Δ marking vector for free places and performs the specified
  # change on the marking vector for all places.
  # 
  def update_marking! Δ_free_places
    @marking_vector += F2A() * Δ_free_places
  end

  # Guards proposed marking delta.
  # 
  def guard_Δ! Δ_free_places
    ary = ( marking_vector + F2A() * Δ_free_places ).column_to_a
    places.zip( ary ).each { |pl, proposed_m| pl.guard.( proposed_m ) }
  end

  # Fires all assignment transitions once.
  # 
  def assignment_transitions_all_fire!
    assignment_closures_for_A.each_with_index do |closure, i|
      @marking_vector = closure.call # TODO: This offers better algorithm.
    end
  end
  alias A_all_fire! assignment_transitions_all_fire!

  # Set marking vector, based on marking array of all places.
  # 
  def set_m_vector new_m
    case new_m
    when Hash then # assume { place => marking } hash argument
      new_m.each_pair { |id, value| place( id ).marking = value }
    when Array then
      msg = "T be a collection with size == net's places!"
      fail TypeError, msg unless new_m.size == places.size
      set_m_vector places >> new_m
    else # convert it with #each
      set_m_vector( new_m.each.map { |e| e }.to_a )
    end
  end

  # Resets recording.
  # 
  def set_recording rec
    @recording = Hash[ rec ]
    return self
  end

  # Duplicates the simulation.
  # 
  def dup( **nn )
    self.class.new( nn.reverse_merge!( { method: @method,
                                         guarded: @guarded,
                                         net: @net,
                                         marking_clamps: @marking_clamps,
                                         initial_marking: @initial_marking
                                       }.update( simulation_settings ) ) )
      .tap { |instance|
        instance.send :set_recording, recording
        instance.send :set_marking_vector, @marking_vector
      }
  end

  # This method constructs a mental image of the supplied net's places, marking
  # clamp prescriptions, and initial marking prescriptions.
  # 
  def init_places( net, marking_clamps, initial_marking,
                   use_default_marking: true )
    @net = net # the mother net
    initialize_parametrized_subclasses
    # Seting up the place and transition collections.
    @places = Places().load( net.places )
    @marking_clamps = MarkingClamps().load( marking_clamps )
    @initial_marking = InitialMarking().load( initial_marking )
    @places.complete_initial_marking( use_default_marking: use_default_marking )
    @f2a = free_places.correspondence_matrix( places )
    @c2a = clamped_places.correspondence_matrix( places )
  end

  # This method constructs a mental image of the supplied net's transitions.
  # 
  def init_transitions( net )
    @transitions = Transitions().load( net.transitions )
    @tS_stoichiometry_matrix = transitions.tS.stoichiometry_matrix
    @TS_stoichiometry_matrix = transitions.TS.stoichiometry_matrix
    @tS_SM = transitions.tS.SM
    @TS_SM = transitions.TS.SM
  end

  # Initialization subroutine that creates parametrized element subclasses
  # representing simulated Petri net elements and their collections.
  # 
  def initialize_parametrized_subclasses
    @Place = Class.new( PlaceRepresentation ).tap &:namespace!
    @Transition = Class.new( TransitionRepresentation ).tap &:namespace!
    @Places = Class.new( Places )
    @Transitions = Class.new( Transitions )
    @MarkingClamps = Class.new( MarkingClamps )
    @InitialMarking = Class.new( InitialMarking )
    tap do |simulation| # Dependency injection.
      [ Place(),
        Transition(),
        Places(),
        Transitions(),
        MarkingClamps(),
        InitialMarking()
      ].each { |klass|
        klass.class_exec { define_method :simulation do simulation end }
      }
    end
  end

  # Sets the initial marking of a place (frontend of +InitialMarking#set+).
  # 
  def set_initial_marking( of: (fail ArgumentError), to: (fail ArgumentError) )
    initial_marking.set( of, to: to )
  end

  # Sets the marking clamp of a place (frontend of +InitialMarking#set+).
  # 
  def set_marking_clamp( of: (fail ArgumentError), to: (fail ArgumentError) )
    marking_clamps.set( of, to: to )
  end

  # Without arguments, constructs the starting marking vector for all places,
  # using either initial values, or clamp values. Optionally, places can be
  # specified, for which the starting vector is returned.
  # 
  def starting_m_vector( places: nil )
    return starting_m_vector( places: places() ) if places.nil?
    places.map { |id|
      pl = place( id )
      if pl.free? then
        pl.initial_marking
      else
        pl.clamp
      end
    }.to_column_vector
  end

  # Without arguments, constructs a zero marking vector for all places.
  # Optionally, places can be specified, for which the zero vector is returned.
  # 
  def zero_m_vector( places: nil )
    return zero_m_vector( places: places() ) if places.nil?
    places.map { |id|
      pl = place( id )
      if pl.free? then
        pl.initial_marking * 0
      else
        pl.clamp * 0
      end
    }.to_column_vector
  end

  # Returns the zero gradient. Optionally, places can be specified, for which
  # the zero vector is returned.
  # 
  def zero_∇( places: nil )
    return zero_∇( places: places() ) if places.nil?
    places.each { |id|
      pl = place( id )
      if pl.free? then
        pl.initial_marking * 0 / time_unit
      else
        pl.clamp * 0 / time_unit
      end
    }.to_column_vector
  end
end # class YPetri::Simulation
