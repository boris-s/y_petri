#encoding: utf-8

require_relative 'simulation/collections'
require_relative 'simulation/timed'

# Represents a simulation of a Petri net, using certain method and settings.
# Simulation concerns (simulation method and settings, initial values, marking
# clamps, guards...) are separated from those Petri net domain model (existence,
# naming, connectivity and function specification of the net). Again, clamps,
# guards, initial values etc. <b>do not belong</b> to the model, although for
# convenience, places may carry default initial marking, default guards, and
# default clamps for use in simulations if none other are specified.
#
class YPetri::Simulation
  include Collections

  SAMPLING_DECIMAL_PLACES = 5
  SIMULATION_METHODS =
    [
      [:pseudo_Euler] # pseudo-timed simulation (like in Cell Illustrator)
    ]
  DEFAULT_SIMULATION_METHOD = :pseudo_Euler

  # Default simulation method (accesses the constant DEFAULT_SIMULATION_METHOD
  # in the receiver's class).
  # 
  def default_simulation_method
    self.class.const_get :DEFAULT_SIMULATION_METHOD
  end

  attr_reader :method, :guarded, :timed, :net
  alias guarded? guarded
  alias timed? timed
  attr_reader :marking_vector
  attr_reader :zero_ᴍ, :zero_gradient
  attr_reader :recording
  alias :r :recording

  # Stoichiometry matrix for *tS* transitions.
  # 
  attr_reader :S_tS

  # Stoichiometry matrix for *TSr* transitions.
  # 
  attr_reader :S_TSr

  # Stoichiometry matrix for *SR* transitions.
  # 
  attr_reader :S_SR

  # Exposing Δ state closures for ts transitions.
  # 
  attr_reader :Δ_closures_for_tsa

  # Note: 'a' in 'tsa' is needed because A (assignment) transitions can also be
  # regarded as a special kind of ts transitions, while they obviously do not
  # act through Δ state, but rather directly enforce marking of their codomain.
  # 
  def Δ_if_tsa_fire_once
    Δ_closures_for_tsa.map( &:call ).reduce( @zero_ᴍ, :+ )
  end

  # Exposing Δ state closures for Tsr transitions.
  # 
  attr_reader :Δ_closures_for_Tsr

  # Delta state contribution for Tsr transitions given Δt.
  # 
  def Δ_Tsr( Δt )
    Δ_closures_for_Tsr.map { |cl| cl.( Δt ) }.reduce( @zero_ᴍ, :+ )
  end
  
  # Exposing action closures for tS transitions.
  # 
  attr_reader :action_closures_for_tS

  # Action vector for if tS transitions fire once. The closures are called
  # in their order, but the state update is not performed between the
  # calls (ie. they fire "simultaneously").
  # 
  def action_vector_for_tS
    Matrix.column_vector action_closures_for_tS.map( &:call )
  end
  alias ᴀ_tS action_vector_for_tS

  # Action vector if tS transitions fire once, like the previous method.
  # But by calling this method, the caller asserts that all timeless
  # transitions in this simulation are stoichiometric (or error is raised).
  #
  def action_vector_for_timeless_transitions
    return action_vector_for_tS if ts_transitions.empty?
    raise "The simulation also contains nonstoichiometric timeless " +
      "transitions! Consider using #action_vector_for_tS."
  end
  alias action_vector_for_t action_vector_for_timeless_transitions
  alias ᴀ_t action_vector_for_timeless_transitions

  # Δ state contribution for tS transitions.
  # 
  def Δ_if_tS_fire_once
    S_tS() * action_vector_for_tS
  end

  # Exposing action closures for TSr transitions.
  # 
  attr_reader :action_closures_for_TSr

  # By calling this method, the caller asserts that all timeless transitions
  # in this simulation are stoichiometric (or error is raised).
  # 
  def action_closures_for_Tr
    return action_closures_for_TSr if self.TSr_transitions.empty?
    raise "The simulation also contains nonstoichiometric timed rateless " +
      "transitions! Consider using #action_closures_for_TSr."
  end

  # Action vector for timed rateless stoichiometric transitions.
  # 
  def action_vector_for_TSr( Δt )
    Matrix.column_vector action_closures_for_TSr.map { |c| c.( Δt ) }
  end
  alias ᴀ_TSr action_vector_for_TSr

  # Action vector for timed rateless stoichiometric transitions
  # By calling this method, the caller asserts that all timeless transitions
  # in this simulation are stoichiometric (or error is raised).
  # 
  def action_vector_for_Tr( Δt )
    return action_vector_for_TSr( Δt ) if TSr_transitions().empty?
    raise "The simulation also contains nonstoichiometric timed rateless " +
      "transitions! Consider using #action_vector_for_TSr."
  end
  alias ᴀ_Tr action_vector_for_Tr

  # State contribution of TSr transitions for the period Δt.
  # 
  def Δ_TSr( Δt )
    S_TSr() * action_vector_for_TSr( Δt )
  end

  # Exposing rate closures for sR transitions.
  # 
  attr_reader :rate_closures_for_sR

  # By calling this method, the caller asserts that there are no rateless
  # transitions in the simulation (or error is raised).
  # 
  def rate_closures_for_nonstoichiometric_transitions
    return rate_closures_for_sR if r_transitions.empty?
    raise "The simulation also contains rateless transitions! Consider " +
      "using #rate_closures_for_sR."
  end
  alias rate_closures_for_s rate_closures_for_nonstoichiometric_transitions

  # State differential for sR transitions.
  # 
  def gradient_for_sR
    rate_closures_for_sR.map( &:call ).reduce( @zero_gradient, :+ )
  end

  # State differential for sR transitions as a hash { place_name: ∂ / ∂ᴛ }.
  # 
  def ∂_sR
    free_pp :gradient_for_sR
  end

  # First-order state contribution of sR transitions during Δt.
  # 
  def Δ_sR( Δt )
    gradient_for_sR * Δt
  end

  # Exposing rate closures for SR transitions.
  # 
  attr_reader :rate_closures_for_SR

  # Rate closures for SR transitions. By calling this method, the caller
  # asserts that there are no rateless transitions in the simulation
  # (or error).
  # 
  def rate_closures_for_stoichiometric_transitions
    return rate_closures_for_SR if r_transitions.empty?
    raise "The simulation also contains rateless transitions! Consider " +
      "using #rate_closures_for_SR"
  end
  alias rate_closures_for_S rate_closures_for_stoichiometric_transitions

  # Rate closures for SR transitions. By calling this method, the caller
  # asserts that there are only SR transitions in the simulation (or error).
  # 
  def rate_closures
    return rate_closures_for_S if s_transitions.empty?
    raise "The simulation contains also nonstoichiometric transitions! " +
      "Consider using #rate_closures_for_S."
  end

  # While rateless stoichiometric transitions provide transition's action as
  # their closure output, SR transitions' closures return flux, which is
  # ∂action / ∂t. This methods return flux for SR transitions as a column
  # vector.
  # 
  def flux_vector_for_SR
    Matrix.column_vector rate_closures_for_SR.map( &:call )
  end
  alias φ_for_SR flux_vector_for_SR

  # Flux vector for a selected collection of SR transitions.
  # 
  def flux_vector_for *transitions
    # TODO
  end
  alias φ_for flux_vector_for

  # Flux vector for SR transitions. Same as the previous method, but the
  # caller asserts that there are only SR transitions in the simulation
  # (or error).
  # 
  def flux_vector
    return flux_vector_for_SR if s_transitions.empty? && r_transitions.empty?
    raise "One may only call this method when all the transitions of the " +
      "simulation are SR transitions. Try #flux_vector_for( *transitions ), " +
      "#flux_vector_for_SR, #flux_for( *transitions ), or #flux_for_SR"
  end
  alias φ flux_vector

  # Flux of SR transitions as an array.
  # 
  def flux_for_SR
    flux_vector_for_SR.column( 0 ).to_a
  end

  # Flux for a selected collection of SR transitions.
  # 
  def flux_for *transitions
    all = SR_transitions :flux_for_SR
    transitions.map { |t| transition t }.map { |e| all[e] }
  end

  # Same as #flux_for_SR, but with caller asserting that there are none but
  # SR transitions in the simulation (or error).
  # 
  def flux
    flux_vector.column( 0 ).to_a
  end

  # Flux of SR transitions as a hash { name: flux }.
  # 
  def f_SR
    SR_tt :flux_for_SR
  end

  # Flux for a selected collection of SR transition as hash { key => flux }.
  # 
  def f_for *transitions
    Hash[ transitions.zip( flux_for *transitions ) ]
  end

  # Same as #f_SR, but with caller asserting that there are none but SR
  # transitions in the simulation (or error).
  # 
  def f
    SR_tt :flux
  end

  # State differential for SR transitions.
  # 
  def gradient_for_SR
    S_SR() * flux_vector_for_SR
  end

  # State differential for SR transitions as a hash { place_name: ∂ / ∂ᴛ }.
  # 
  def ∂_SR
    free_pp :gradient_for_SR
  end

  # First-order action vector for SR transitions for the time period Δt.
  # 
  def first_order_action_vector_for_SR( Δt )
    flux_vector_for_SR * Δt
  end
  alias ᴀ_SR first_order_action_vector_for_SR

  # First-order action (as array) for SR for the time period Δt.
  # 
  def first_order_action_for_SR( Δt )
    first_order_action_vector_for_SR( Δt ).column( 0 ).to_a
  end

  # First-order state contribution of SR transitions during Δt.
  # 
  def Δ_SR( Δt )
    gradient_for_SR * Δt
  end

  # First-order state contribution for SR transitions during Δt (as array).
  # 
  def Δ_array_for_SR( Δt )
    Δ_Euler_for_SR( Δt ).column( 0 ).to_a
  end

  # Exposing assignment closures for A transitions.
  #
  attr_reader :assignment_closures_for_A

  # Returns the array of places to which the assignment transitions assign.
  # 
  def A_target_places
    # TODO
  end

  # Like #A_target_places, but returns place names.
  # 
  def A_target_pp
    # TODO
  end

  # Returns the assignments as they would if all A transitions fired now,
  # as a hash { place => assignment }.
  # 
  def assignments
    # TODO
  end

  # Like #assignments, but place names are used instead { name: assignment }.
  # 
  def a
    # TODO
  end

  # Returns the assignments as a column vector.
  # 
  def A_action
    Matrix.column_vector( assignments.reduce( free_places { nil } ) do |α, p|
                            α[p] = marking
                          end )
    # TODO: Assignment action to a clamped place should result in a warning.
  end

  # Correspondence matrix free places => all places.
  # 
  attr_reader :F2A

  # Correspondence matrix clamped places => all places.
  # 
  attr_reader :C2A

  # Simulation settings.
  # 
  def settings; {} end
  alias :simulation_settings :settings

  def recording_csv_string
    CSV.generate do |csv|
      @recording.keys.zip( @recording.values ).map{ |a, b| [ a ] + b.to_a }
        .each{ |line| csv << line }
    end        
  end

  # Currently, simulation is largely immutable. Net, initial marking, clamps
  # and simulation settings are set upon initialization, whereupon the instance
  # forms their "mental image", which remains immune to any subsequent changes
  # to the original objects. Required parameters are :net, :marking_clamps, and
  # :initial_marking. Optional is :method (simulation method), and :guarded
  # (true/false, whether the simulation guards the transition function results).
  # Guard conditions can be either implicit (guarding against negative values
  # and against type changes in by transition action), or explicitly associated
  # with either places, or transition function results.
  # 
  # A simulation distinguishes between free and clamped places. For free
  # places, initial marking has to be specified. For clamped places, marking
  # clamps have to be specified. Both come as hashes:
  # 
  # In addition to the arguments required by the regular simulation
  # constructor, timed simulation constructor also expects :step_size
  # (alias :step), :sampling_period (alias :sampling), and :target_time
  # named arguments.
  # 
  def initialize( method: default_simulation_method,
                  guarded: false,
                  marking_clamps: {},
                  initial_marking: {},
                  **nn )
    puts "constructing a simulation" if YPetri::DEBUG

    @method, @guarded = method, guarded
    @net = nn.fetch( :net )
    @places, @transitions = @net.places.dup, @net.transitions.dup
    self.singleton_class.class_exec {
      define_method :Place do net.send :Place end
      define_method :Transition do net.send :Transition end
      define_method :Net do net.send :Net end
      private :Place, :Transition, :Net
    }; puts "setup of :net mental image complete" if YPetri::DEBUG

    @marking_clamps = marking_clamps.with_keys { |k| place k }
    @initial_marking = initial_marking.with_keys { |k| place k }
    # Enforce that keys in the hashes must be unique:
    @marking_clamps.keys.aT_equal @marking_clamps.keys.uniq
    @initial_marking.keys.aT_equal @initial_marking.keys.uniq
    puts "setup of clamps and initial marking done" if YPetri::DEBUG

    places.each { |pl| # each place must have either clamp, or initial marking
      pl.aT "place #{pl}", "have either clamp or initial marking" do |pl|
        ( @marking_clamps.keys + @initial_marking.keys ).include? pl
      end
    }; puts "clamp || initial marking test passed" if YPetri::DEBUG

    # @F2A * ᴍ (marking vector of free places) maps ᴍ to all places.
    @F2A = Matrix.correspondence_matrix( free_places, places )
    # @C2A * marking_vector_of_clamped_places maps it to all places.
    @C2A = Matrix.correspondence_matrix( clamped_places, places )
    puts "correspondence matrices set up" if YPetri::DEBUG

    # Stoichiometry matrices:
    @S_tS = S_for tS_transitions()
    @S_SR = S_for SR_transitions()
    @S_TSr = S_for TSr_transitions()
    puts "stoichiometry matrices set up" if YPetri::DEBUG

    # Other assets:
    @Δ_closures_for_tsa = create_Δ_closures_for_tsa
    @Δ_closures_for_Tsr = create_Δ_closures_for_Tsr
    @action_closures_for_tS = create_action_closures_for_tS
    @action_closures_for_TSr = create_action_closures_for_TSr
    @rate_closures_for_sR = create_rate_closures_for_sR
    @rate_closures_for_SR = create_rate_closures_for_SR
    @assignment_closures_for_A = create_assignment_closures_for_A
    @zero_ᴍ = compute_initial_marking_vector_of_free_places.map { |e| e * 0 }
    @zero_gradient = @zero_ᴍ.dup
    puts "other assets set up" if YPetri::DEBUG

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

    puts "timedness of the simulation decided" if YPetri::DEBUG 

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

  # ==== Sparse stoichiometry vectors for transitions

  # For the transition specified by the argument, this method returns the
  # sparse stoichiometry vector corresponding to the free places.
  # 
  def sparse_σ transition
    instance = transition( transition )
    raise AE, "Transition #{transition} not stoichiometric!" unless
      instance.stoichiometric?
    Matrix.correspondence_matrix( instance.codomain, free_places ) *
      Matrix.column_vector( instance.stoichiometry )
  end

  # For the transition specified by the argument, this method returns the
  # sparse stoichiometry vector mapped to all the places of the simulation.
  # 
  def sparse_stoichiometry_vector transition
    instance = transition( transition )
    raise AE, "Transition #{transition} not stoichiometric!" unless
      instance.stoichiometric?
    Matrix.correspondence_matrix( instance.codomain, places ) *
      Matrix.column_vector( instance.stoichiometry )
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

  private

  # Resets the simulation
  # 
  def reset!
    puts "Starting #reset! method" if YPetri::DEBUG

    mv_clamped = compute_marking_vector_of_clamped_places
    puts "#reset! obtained marking vector of clamped places" if YPetri::DEBUG
    clamped_component = C2A() * mv_clamped
    puts "clamped component of marking vector prepared:\n#{clamped_component}" if YPetri::DEBUG

    mv_free = compute_initial_marking_vector_of_free_places
    puts "#reset! obtained initial marking vector of free places" if YPetri::DEBUG
    free_component = F2A() * mv_free
    puts "free component of marking vector prepared:\n#{free_component}" if YPetri::DEBUG
    
    # zero_vector = Matrix.column_vector( places.map { SY::ZERO rescue 0 } ) # Float zeros
    zero_vector = Matrix.column_vector( places.map { 0 } ) # Float zeros
    puts "zero vector prepared: #{zero_vector}" if YPetri::DEBUG

    free_component.aT { |v|
      qnt = v.first.quantity rescue :no_quantity
      unless qnt == :no_quantity
        v.all? { |e| e.quantity == qnt }
      else true end
    } if YPetri::DEBUG
    puts "free component of marking vector checked" if YPetri::DEBUG

    @marking_vector = free_component + clamped_component
    # Matrix
    #   .column_vector( places.map.with_index do |_, i|
    #                     clamped_component[i, 0] || free_component[i, 0]
    #                   end )

    puts "marking vector assembled\n#{m}\n, about to reset recording" if YPetri::DEBUG
    reset_recording!
    puts "reset recording done, about to initiate sampling process" if YPetri::DEBUG
    note_state_change!
    puts "sampling process initiated, #reset! done" if YPetri::DEBUG
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

  # Called upon initialzation
  # 
  def compute_initial_marking_vector_of_free_places
    puts "computing the marking vector of free places" if YPetri::DEBUG
    results = free_places.map { |p|
      im = @initial_marking[ p ]
      puts "doing free place #{p} with init. marking #{im}" if YPetri::DEBUG
      # unwrap places / cells
      im = case im
           when YPetri::Place then im.marking
           else im end
      case im
      when Proc then im.call
      else im end
    }
    # and create the matrix out of the results
    puts "about to create the column vector" if YPetri::DEBUG
    cv = Matrix.column_vector results
    puts "column vector #{cv} prepared" if YPetri::DEBUG
    return cv
  end

  # Called upon initialization
  # 
  def compute_marking_vector_of_clamped_places
    puts "computing the marking vector of clamped places" if YPetri::DEBUG
    results = clamped_places.map { |p|
      clamp = @marking_clamps[ p ]
      puts "doing clamped place #{p} with clamp #{clamp}" if YPetri::DEBUG
      # unwrap places / cells
      clamp = case clamp
              when YPetri::Place then clamp.marking
              else clamp end
      # unwrap closure by calling it
      case clamp
      when Proc then clamp.call
      else clamp end
    }
    # and create the matrix out of the results
    puts "about to create the column vector" if YPetri::DEBUG
    cv = Matrix.column_vector results
    puts "column vector #{cv} prepared" if YPetri::DEBUG
    return cv
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

  # ----------------------------------------------------------------------
  # Methods to create other instance assets upon initialization.
  # These instance assets are created at the beginning, so the work
  # needs to be performed only once in the instance lifetime.

  def create_Δ_closures_for_tsa
    tsa_transitions.map { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      if guarded? then
        -> {
          domain_marking = ( p2d * marking_vector ).column_to_a
          # I. TODO: t.domain_guard.( domain_marking )
          codomain_change = Array t.action_closure.( *domain_marking )
          # II. TODO: t.action_guard.( codomain_change )
          c2f * codomain_change
        }
      else
        -> { c2f * t.action_closure.( *( p2d * marking_vector ).column_to_a ) }
      end
    }
  end

  def blame_tsa( marking_vect )
    # If, in spite of passing domain guard and action guard, marking guard
    # indicates an exception, the method here serves to find the candidate
    # transitions to blame for the exception, given certain place marking.
    msg = "Action closure of transition #%{t} with domain #%{dm} and " +
      "codomain #%{cdm} returns #%{retval} which, when added to place " +
      "#{p}, gives marking that would flunk place's marking guard."
    tsa_transitions.each { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      rslt = Array t.action_closure( *( p2d * marking_vect ).column_to_a )
      t.codomain.zip( rslt ).each { |place, Δ|
        fields = {
          t: t.name || t.object_id, p: place,
          dm: Hash[ t.domain_pp.zip domain_marking ],
          cdm: Hash[ t.codomain_pp.zip( t.codomain.map { |p| ꜧ[p] } ) ],
          retval: Hash[ t.codomain_pp.zip( codomain_change ) ]
        }
        rslt = ꜧ[place] + Δ
        raise TypeError, msg % fields unless place.marking_guard.( rslt )
      }
    }
    # TODO: Here, #blame_tsa simply raises. It would be however more correct
    # to gather all blame candidates and present them to the user all.
  end

  def create_Δ_closures_for_Tsr
    Tsr_transitions().map { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      -> Δt { c2f * t.action_closure.( Δt, *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_action_closures_for_tS
    tS_transitions.map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      -> { t.action_closure.( *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_action_closures_for_TSr
    TSr_transitions().map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      -> Δt { t.action_closure.( Δt, *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_rate_closures_for_sR
    sR_transitions.map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      -> { c2f * t.rate_closure.( *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_rate_closures_for_SR
    SR_transitions().map { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      puts "Marking is #{pp :marking rescue nil}" if YPetri::DEBUG
      -> { t.rate_closure.( *( p2d * marking_vector ).column_to_a )
           .tap do |r| fail YPetri::GuardError, "SR #{t.name}!!!!" if r.is_a? Complex end
      }
    }
  end

  def create_assignment_closures_for_A
    nils = places.map { nil }
    A_transitions().map { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      zero_vector = Matrix.column_vector( places.map { 0 } )
      probe = Matrix.column_vector( t.codomain.size.times.map { |a| a + 1 } )
      result = ( F2A() * c2f * probe ).column_to_a.map { |n| n == 0 ? nil : n }
      assignment_addresses = probe.column_to_a.map { |i| result.index i }
      -> {
        act = Array t.action_closure.( *( p2d * marking_vector ).column_to_a )
        act.each_with_index { |e, i|
          fail YPetri::GuardError, "Assignment transition #{t.name} with " +
          "domain #{t.domain_pp( domain_marking )} has produced a complex " +
          "number at output positon #{i} (output was #{act})!" if e.is_a?( Complex ) || i.is_a?( Complex )
        }
        assign = assignment_addresses.zip( act )
          .each_with_object nils.dup do |pair, o| o[pair[0]] = pair[1] end
        marking_vector.map { |orig_val| assign.shift || orig_val }
      }
    } # map
end

  # Set marking vector (for all places).
  # 
  def set_marking_vector marking_vector
    @marking_vector = marking_vector
    return self
  end

  # Set marking vector, based on marking array of all places.
  # 
  def set_marking marking_array
    set_marking_vector Matrix.column_vector( marking_array )
  end

  # Update marking vector, based on { place => marking } hash argument.
  # 
  def update_marking_from_a_hash marking_hash
    to_set = place_marking.merge( marking_hash.with_keys do |k| place k end )
    set_marking( places.map { |pl| to_set[ pl ] } )
  end

  # Set marking vector based on marking array of free places.
  # 
  def set_m marking_array_for_free_places
    set_marking_from_a_hash( free_places( marking_array_for_free_places ) )
  end

  # Set marking vector based on marking vector of free places.
  # 
  def set_ᴍ marking_vector_for_free_places
    set_m( marking_vector_for_free_places.column_to_a )
  end

  # Private method for resetting recording.
  # 
  def set_recording rec
    @recording = Hash[ rec ]
    return self
  end

  # Duplicate creation.
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

  # Instance identification methods.
  # 
  def place( which ); Place().instance( which ) end
  def transition( which ); Transition().instance( which ) end
end # class YPetri::Simulation
