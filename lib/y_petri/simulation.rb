#encoding: utf-8

-> *a do a.each { |e| require_relative "simulation/#{e}" } end
  .( 'init',
     'matrix',
     'dependency_injection',
     'element_representation',
     'elements',
     'elements/access',
     'place_representation',
     'places',
     'places/access',
     'transition_representation',
     'transitions',
     'transitions/access',
     'place_mapping',
     'marking_clamps',
     'marking_clamps/access',
     'initial_marking',
     'initial_marking/access',
     'marking_vector',
     'marking_vector/access',
     'recording',
     'recording/access',
     'core',
     'timeless',
     'timed' )

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
  include Recording::Access
  include MarkingVector::Access

  # Parametrized subclasses:
  attr_reader :Place,
              :Transition,
              :Elements,
              :Places,
              :Transitions,
              :PlaceMapping,
              :MarkingClamps,
              :InitialMarking,
              :MarkingVector,
              :Recording,
              :Core

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
           :guarded,
           :step!,
           to: :core

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
  def initialize method: nil,
                 guarded: false,
                 net: ( fail ArgumentError, "Net missing!" ),
                 marking_clamps: {},
                 initial_marking: {},
                 use_default_marking: true,
                 **nn

    @net = net
    @guarded = guarded
    init_parametrized_subclasses
    init_places( marking_clamps, initial_marking,
                 use_default_marking: use_default_marking )
    @m_vector = MarkingVector().zero
    if nn.has?( :time, syn!: :time_range ) ||
        nn.has?( :step, syn!: :time_step ) ||
        nn.has?( :sampling, syn!: :sampling_period )
      extend Timed
    else
      extend Timeless
    end

    init_transitions

    init **nn # Timed / Timeless dependent initialization

    # Init the timeless closures.
    @ts_delta_closure = transitions.ts.delta_closure
    @tS_firing_closure = transitions.tS.firing_closure
    @A_assignment_closure = transitions.A.assignment_closure
    @increment_marking_vector_closure = m_vector.increment_closure

    # Init the timed closures, if timed?.
    if timed? then
      @Ts_gradient_closure = transitions.Ts.gradient_closure
      @TS_rate_closure = transitions.TS.rate_closure
    end

    # Init the core.
    @core = Core().new( method: method, guarded: guarded  )

    reset!
  end

  # Simulation settings.
  # 
  def settings
    { method: method,
      guarded: guarded,
      net: net,
      marking_clamps: marking_clamps.keys_to_source_places,
      initial_marking: initial_marking.keys_to_source_places
    }
  end
  alias :simulation_settings :settings

  # Returns a new simulation instance. Unless modified by arguments, the state
  # of the new instance is the same as the creator's. Arguments can partially or
  # wholly modify the attributes of the duplicate.
  # 
  def dup marking: marking, recording: recording, **nn
    self.class.new( nn.reverse_merge! settings ).tap do |dup|
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
  alias at dup

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
  alias include? includes?

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
end # class YPetri::Simulation
