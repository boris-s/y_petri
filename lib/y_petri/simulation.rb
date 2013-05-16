#encoding: utf-8

# Emphasizing separation of concerns, the model is defined as agnostic of
# simulation settings. Only for the purpose of simulation, model is combined
# together with specific simulation settings. Simulation settings consist of
# global settings (eg. time step, sampling rate...) and object specific
# settings (eg. clamps, constraints...). Again, clamps and constraints *do
# not* belong to the model. Simulation methods are also concern of this
# class, not the model class. Thus, simulation is not done by calling
# instance methods of the model. Instead, this class makes a 'mental image'
# of the model and only that is used for actual simulation.
#
class YPetri::Simulation
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

  # Exposing @recording
  # 
  attr_reader :recording
  alias :r :recording

  # Zero marking vector.
  # 
  attr_reader :zero_ᴍ

  # Zero gradient.
  # 
  attr_reader :zero_gradient

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
  def initialize( method: default_simulation_method,
                  guarded: false,
                  net: raise( ArgumentError, "Net argument absent!" ),
                  marking_clamps: {},
                  initial_marking: {} )
    puts "starting to set up Simulation" if YPetri::DEBUG
    @method, @guarded, @net = method, guarded, net
    @places, @transitions = @net.places.dup, @net.transitions.dup
    self.singleton_class.class_exec {
      define_method :Place do net.send :Place end
      define_method :Transition do net.send :Transition end
      define_method :Net do net.send :Net end
      private :Place, :Transition, :Net
    }; puts "setup of :net mental image complete" if YPetri::DEBUG

    # A simulation distinguishes between free and clamped places. For free
    # places, initial marking has to be specified. For clamped places, marking
    # clamps have to be specified. Both come as hashes:
    @marking_clamps = marking_clamps.with_keys { |k| place k }
    @initial_marking = initial_marking.with_keys { |k| place k }
    # Enforce that keys in the hashes must be unique:
    @marking_clamps.keys.aT_equal @marking_clamps.keys.uniq
    @initial_marking.keys.aT_equal @initial_marking.keys.uniq
    puts "setup of clamps and initial marking done" if YPetri::DEBUG

    # Each place must have either clamp, or initial marking:
    places.each { |pl|
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
    @S_for_tS = S_for tS_transitions()
    @S_for_SR = S_for SR_transitions()
    @S_for_TSr = S_for TSr_transitions()
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
    puts "other assets set up, about to reset" if YPetri::DEBUG

    reset!; puts "reset complete" if YPetri::DEBUG
  end

  # Returns a new instance of the system simulation at a specified state, with
  # same simulation settings. This state (:marking argument) can be specified
  # either as marking vector for free or all places, marking array for free or
  # all places, or marking hash. If vector or array is given, its size must
  # correspond to the number of either free, or all places. If hash is given,
  # it is not necessary to specify marking of every place – marking of those
  # left out will be left same as in the current state.
  # 
  def at( marking: marking, **oo )
    err_msg = "Size of supplied marking must match either the number of " +
      "free places, or the number of all places!"
    update_method = case marking
                    when Hash then :update_marking_from_a_hash
                    when Matrix then
                      case marking.column_to_a.size
                      when places.size then :set_marking_vector
                      when free_places.size then :set_ᴍ
                      else raise TypeError, err_msg end
                    else # marking assumed to be an array
                      case marking.size
                      when places.size then :set_marking
                      when free_places.size then :set_m
                      else raise TypeError, err_msg end
                    end
    return duplicate( **oo ).send( update_method, marking )
  end

  # Exposing @net.
  # 
  attr_reader :net

  # Is the simulation guarded?
  # 
  def guarded?; @guarded end

  # Without arguments or block, it returns simply a list of places. Otherwise,
  # it returns a has whose keys are the places, and whose values are governed
  # by the supplied parameters (either another collection, or message to #send
  # to self to obtain a second collection).
  # 
  def places *aa, &b
    return @places.dup if aa.empty? && b.nil?
    zip_to_hash places, *aa, &b
  end

  # Without arguments or block, it returns simply a list of transitions.
  # Otherwise, it returns a has whose keys are the places, and whose values are
  # governed by the supplied parameters (either another collection, or message
  # to #send to self to obtain a second collection).
  # 
  def transitions *aa, &b
    return @transitions.dup if aa.empty? && b.nil?
    zip_to_hash transitions, *aa, &b
  end

  # Without arguments or block, it returns simply a list of place names.
  # Otherwise, it returns a hash whose keys are place names, and whose values
  # are determined by the supplied argument(s) and/or block (either another
  # collection, or a message to #send to self to obtain such collection). Unary
  # block can be supplied to modify these values.
  #
  def pp *aa, &b
    return places.map &:name if aa.empty? && b.nil?
    zip_to_hash( places.map { |p| p.name || p }, *aa, &b )
  end

  # Without arguments or block, it returns simply a list of transition names.
  # Otherwise, it returns a hash whose keys are transition names, and whose
  # values are determined by the supplied argument(s) and/or block (either
  # another collection, or a message to #send to self to obtain such collection).
  # Unary block can be supplied to modify these values.
  #
  def tt *aa, &b
    return transitions.map &:name if aa.empty? && b.nil?
    zip_to_hash( transitions.map { |t| t.name || t }, *aa, &b )
  end

  # Without arguments or block, it returns simply a list of free places.
  # Otherwise, it returns a hash, whose keys are the free places, and whose
  # values are governed by the supplied parameters (either another collection,
  # or message to #send to self to obtain a second collection).
  # 
  def free_places *aa, &b
    return zip_to_hash free_places, *aa, &b unless aa.empty? && b.nil?
    kk = @initial_marking.keys
    places.select { |p| kk.include? p }
  end

  # Behaves like #free_places, except that it uses place names instead of
  # instances whenever possible.
  # 
  def free_pp *aa, &b
    return free_places.map { |p| p.name || p } if aa.empty? && b.nil?
    zip_to_hash free_pp, *aa, &b
  end

  # Initial marking definitions for free places (array).
  # 
  def im
    free_places.map { |p| @initial_marking[p] }
  end

  # Marking array of all places as it appears at the beginning of a simulation.
  # 
  def initial_marking
    raise # FIXME: "Initial marking" for all places (ie. incl. clamped ones).
  end

  # Initial marking of free places as a column vector.
  # 
  def im_vector
    Matrix.column_vector im
  end
  alias iᴍ im_vector

  # Marking of all places at the beginning of a simulation, as a column vector.
  # 
  def initial_marking_vector
    Matrix.column_vector initial_marking
  end

  # Without arguments or block, it returns simply a list of clamped places.
  # Otherwise, it returns a hash, whose keys are the places, and whose values
  # are governed by the supplied parameters (either another collection, or
  # message to #send to self to obtain a second collection).
  # 
  def clamped_places *aa, &b
    return zip_to_hash clamped_places, *aa, &b unless aa.empty? && b.nil?
    kk = @marking_clamps.keys
    places.select { |p| kk.include? p }
  end

  # Behaves like #clamped_places, except that it uses place names instead of
  # instances whenever possible.
  # 
  def clamped_pp *aa, &b
    return clamped_places.map { |p| p.name || p } if aa.empty? && b.nil?
    zip_to_hash clamped_pp, *aa, &b
  end

  # Place clamp definitions for clamped places (array)
  # 
  def marking_clamps
    clamped_places.map { |p| @marking_clamps[p] }
  end
  alias place_clamps marking_clamps

  # Marking array of free places.
  # 
  def m
    m_vector.column_to_a
  end

  # Marking hash of free places { name: marking }.
  # 
  def pm
    free_pp :m
  end
  alias p_m pm

  # Marking hash of free places { place: marking }.
  # 
  def place_m
    free_places :m
  end

  # Marking array of all places.
  # 
  def marking
    marking_vector ? marking_vector.column_to_a : nil
  end

  # Marking hash of all places { name: marking }.
  # 
  def pmarking
    pp :marking
  end
  alias p_marking pmarking

  # Marking hash of all places { place: marking }.
  # 
  def place_marking
    places :marking
  end

  # Marking of a specified place(s)
  # 
  def marking_of place_or_collection_of_places
    if place_or_collection_of_places.respond_to? :each then
      place_or_collection_of_places.map { |pl| place_marking[ place( pl ) ] }
    else
      place_marking[ place( place_or_collection_of_places ) ]
    end
  end
  alias m_of marking_of

  # Marking of free places as a column vector.
  # 
  def m_vector
    F2A().t * @marking_vector
  end
  alias ᴍ m_vector

  # Marking of clamped places as a column vector.
  # 
  def marking_vector_of_clamped_places
    C2A().t * @marking_vector
  end
  alias ᴍ_clamped marking_vector_of_clamped_places

  # Marking of clamped places as an array.
  # 
  def marking_of_clamped_places
    ᴍ_clamped.column( 0 ).to_a
  end
  alias m_clamped marking_of_clamped_places

  # Marking of all places as a column vector.
  # 
  attr_reader :marking_vector

  # Creation of stoichiometry matrix for an arbitrary array of stoichio.
  # transitions, that maps (has the number of rows equal to) the free places.
  # 
  def S_for( array_of_S_transitions )
    array_of_S_transitions.map { |t| sparse_σ t }
      .reduce( Matrix.empty( free_places.size, 0 ), :join_right )
  end

  # Creation of stoichiometry matrix for an arbitrary array of stoichio.
  # transitions, that maps (has the number of rows equal to) all the places.
  # 
  def stoichiometry_matrix_for( array_of_S_transitions )
    array_of_S_transitions.map { |t| sparse_stoichiometry_vector t }
      .reduce( Matrix.empty( places.size, 0 ), :join_right )
  end

  # 3. Stoichiometry matrix for timeless stoichiometric transitions.
  # 
  attr_reader :S_for_tS

  # 4. Stoichiometry matrix for timed rateless stoichiometric transitions.
  # 
  attr_reader :S_for_TSr

  # 6. Stoichiometry matrix for stoichiometric transitions with rate.
  # 
  attr_reader :S_for_SR

  # Stoichiometry matrix, with the distinction, that the caller asserts,
  # that all transitions in this simulation are stoichiometric transitions
  # with rate (or error).
  # 
  def S
    return S_for_SR() if s_transitions.empty? && r_transitions.empty?
    raise "The simulation contains also non-stoichiometric transitions! " +
      "Consider using #S_for_SR."
  end

  # ==== 1. Exposing ts transitions

  # Without arguments or block, it returns simply a list of timeless
  # nonstoichiometric transitions. Otherwise, it returns a hash, whose keys
  # are the ts transitions, and values are governed by the supplied parameters
  # (either another collection, or a message to #send to self to obtain the
  # collection of values).
  # 
  def ts_transitions *aa, &b
    return zip_to_hash ts_transitions, *aa, &b unless aa.empty? && b.nil?
    sift_from_net :ts_transitions
  end

  # Like #ts_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def ts_tt *aa, &b
    return zip_to_hash ts_tt, *aa, &b unless aa.empty? && b.nil?
    ts_transitions.map { |t| t.name || t }
  end

  # Assignment transitions (A transition) can be regarded as a special kind
  # of ts transition (subtracting away the current marking of their domain
  # and replacing it with the result of their function). But it may often
  # be useful to exclude A transitions from among the ts transitions, and
  # such set is called tsa transitions (timeless nonstoichiometric
  # nonassignment transitions).
  # 
  def tsa_transitions *aa, &b
    return zip_to_hash tsa_transitions, *aa, &b unless aa.empty? && b.nil?
    sift_from_net :tsa_transitions
  end

  # Like #tsa_transitions, except that transition names are used instead of
  # instance, whenever possible.
  # 
  def tsa_tt *aa, &b
    return zip_to_hash tsa_tt, *aa, &b unless aa.empty? && b.nil?
    tsa_transitions.map { |t| t.name || t }
  end

  # ==== 2. Exposing tS transitions

  # Without arguments or block, it returns simply a list of timeless
  # stoichiometric transitions. Otherwise, it returns a hash, whose keys are
  # the tS transitions, and values are governed by the supplied parameters
  # (either another collection, or a message to #send to self to obtain the
  # collection of values).
  # 
  def tS_transitions *aa, &b
    return zip_to_hash tS_transitions, *aa, &b unless aa.empty? && b.nil?
    sift_from_net :tS_transitions
  end

  # Like #tS_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def tS_tt *aa, &b
    return zip_to_hash tS_tt, *aa, &b unless aa.empty? && b.nil?
    tS_transitions.map { |t| t.name || t }
  end

  # ==== 3. Exposing Tsr transitions

  # Without arguments or block, it returns simply a list of timed rateless
  # nonstoichiometric transitions. Otherwise, it returns a hash, whose keys
  # are the Tsr transitions, and whose values are governed by the supplied
  # arguments (either an explicit collection of values, or a message to #send
  # to self to obtain such collection).
  # 
  def Tsr_transitions *aa, &b
    return zip_to_hash Tsr_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :Tsr_transitions
  end

  # Like #Tsr_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def Tsr_tt *aa, &b
    return zip_to_hash Tsr_tt(), *aa, &b unless aa.empty? && b.nil?
    Tsr_transitions().map { |t| t.name || t }
  end

  # ==== 4. Exposing TSr transitions

  # Without arguments or block, it returns simply a list of timed rateless
  # stoichiometric transitions. Otherwise, it returns a hash, whose keys are
  # are the TSr transitions, and whose values are governed by the supplied
  # arguments (either an explicit collection of values, or a message to #send
  # to self to obtain such collection).
  # 
  def TSr_transitions *aa, &b
    return zip_to_hash TSr_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :TSr_transitions
  end

  # Like #TSr_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def TSr_tt *aa, &b
    return zip_to_hash TSr_tt(), *aa, &b unless aa.empty? && b.nil?
    TSr_transitions().map { |t| t.name || t }
  end

  # ==== 5. Exposing sR transitions

  # Without arguments or block, it returns simply a list of nonstoichiometric
  # transitions with rate. Otherwise, it returns a hash, whose keys are
  # are the sR transitions, and whose values are governed by the supplied
  # arguments (either an explicit collection of values, or a message to #send
  # to self to obtain such collection).
  # 
  def sR_transitions *aa, &b
    return zip_to_hash sR_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :sR_transitions
  end

  # Like #sR_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def sR_tt *aa, &b
    return zip_to_hash sR_tt(), *aa, &b unless aa.empty? && b.nil?
    sR_transitions.map { |t| t.name || t }
  end

  # ==== 6. Exposing SR transitions

  # Without arguments or block, it returns simply a list of stoichiometric
  # transitions with rate. Otherwise, it returns a hash, whose keys are
  # are the SR transitions, and whose values are governed by the supplied
  # arguments (either an explicit collection of values, or a message to #send
  # to self to obtain such collection).
  # 
  def SR_transitions *aa, &b
    return zip_to_hash SR_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :SR_transitions
  end

  # Like #SR_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def SR_tt *aa, &b
    return zip_to_hash SR_tt(), *aa, &b unless aa.empty? && b.nil?
    SR_transitions().map { |t| t.name || t }
  end

  # ==== Assignment (A) transitions

  # Without arguments or block, it returns simply a list of assignment
  # transitions. Otherwise, it returns a hash, whose keys are the A
  # transitions, and whose values are governed by the supplied arguments
  # (either an explicit collection of values, or a message to #send
  # to self to obtain such collection).
  # 
  def A_transitions *aa, &b
    return zip_to_hash A_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :A_transitions
  end
  alias assignment_transitions A_transitions

  # Like #A_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def A_tt *aa, &b
    return zip_to_hash A_tt(), *aa, &b unless aa.empty? && b.nil?
    A_transitions().map { |t| t.name || t }
  end
  alias assignment_tt A_tt

  # ==== Stoichiometric transitions of any kind (S transitions)

  # Without arguments or block, it returns simply a list of stoichiometric
  # transitions. Otherwise, it returns a hash, whose keys are the S
  # transitions, and whose values are governed by the supplied arguments
  # (either an explicit collection of values, or a message to #send to
  # self to obtain such collection).
  # 
  def S_transitions *aa, &b
    return zip_to_hash S_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :S_transitions
  end

  # Like #S_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def S_tt *aa, &b
    return zip_to_hash S_tt(), *aa, &b unless aa.empty? && b.nil?
    S_transitions().map { |t| t.name || t }
  end

  # ==== Nonstoichiometric transitions of any kind (s transitions)

  # Without arguments or block, it returns simply a list of
  # nonstoichiometric transitions. Otherwise, it returns a hash, whose
  # keys are the s transitions, and whose values are governed by the
  # supplied arguments (either an explicit collection of values, or a
  # message to #send to self to obtain such collection).
  # 
  def s_transitions *aa, &b
    return zip_to_hash s_transitions, *aa, &b unless aa.empty? && b.nil?
    sift_from_net :s_transitions
  end

  # Like #s_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def s_tt *aa, &b
    return zip_to_hash s_tt, *aa, &b unless aa.empty? && b.nil?
    s_transitions.map { |t| t.name || t }
  end

  # ==== Transitions with rate (R transitions), otherwise of any kind

  # Without arguments or block, it returns simply a list of transitions
  # with rate. Otherwise, it returns a hash, whose keys are the R
  # transitions, and whose values are governed by the supplied arguments
  # (either an explicit collection of values, or a message to #send to
  # self to obtain such collection).
  # 
  def R_transitions *aa, &b
    return zip_to_hash R_transitions(), *aa, &b unless aa.empty? && b.nil?
    sift_from_net :R_transitions
  end

  # Like #s_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def R_tt *aa, &b
    return zip_to_hash R_tt(), *aa, &b unless aa.empty? && b.nil?
    R_transitions().map { |t| t.name || t }
  end

  # ==== Rateless transitions (r transitions), otherwise of any kind

  # Without arguments or block, it returns simply a list of rateless
  # transitions. Otherwise, it returns a hash, whose keys are the r
  # transitions, and whose values are governed by the supplied arguments
  # (either an explicit collection of values, or a message to #send to
  # self to obtain such collection).
  # 
  def r_transitions *aa, &b
    return zip_to_hash r_transitions, *aa, &b unless aa.empty? && b.nil?
    sift_from_net :r_transitions
  end

  # Like #r_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def r_tt *aa, &b
    return zip_to_hash r_tt, *aa, &b unless aa.empty? && b.nil?
    r_transitions.map { |t| t.name || t }
  end

  # === Methods presenting other simulation assets

  # ==== Regarding ts transitions
  # 
  # (Their closures supply directly Δ codomain.)

  # Exposing Δ state closures for ts transitions.
  # 
  attr_reader :Δ_closures_for_tsa

  # Delta state contribution if timed nonstoichiometric non-assignment (tsa)
  # transitions fire once. The closures are called in their order, but the state
  # update is not performed between the calls (they fire simultaneously).
  #
  # Note: 'a' in 'tsa' is needed because A (assignment) transitions can also be
  # regarded as a special kind of ts transitions, while they obviously do not
  # act through Δ state, but rather directly enforce marking of their codomain.
  # 
  def Δ_if_tsa_fire_once
    Δ_closures_for_tsa.map( &:call ).reduce( @zero_ᴍ, :+ )
  end

  # ==== Regarding Tsr transitions
  # 
  # (Their closures do take Δt as argument, but do not expose their ∂,
  # and they might not even have one.)

  # Exposing Δ state closures for Tsr transitions.
  # 
  attr_reader :Δ_closures_for_Tsr

  # Delta state contribution for Tsr transitions given Δt.
  # 
  def Δ_for_Tsr( Δt )
    Δ_closures_for_Tsr.map { |cl| cl.( Δt ) }.reduce( @zero_ᴍ, :+ )
  end

  # ==== Regarding tS transitions
  # 
  # (These transitions are timeless, but stoichiometric. It means that their
  # closures do not output Δ state contribution directly, but instead they
  # output a single number, which is a transition action, and Δ state is then
  # computed from it by multiplying the the action vector with the
  # stoichiometry matrix.

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
  alias α_for_tS action_vector_for_tS

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
  alias α_for_t action_vector_for_timeless_transitions

  # Δ state contribution for tS transitions.
  # 
  def Δ_if_tS_fire_once
    S_for_tS() * action_vector_for_tS
  end

  # ==== Regarding TSr transitions
  # 
  # (Same as Tsr, but stoichiometric. That is, their closures do not return
  # Δ contribution, but transition's action, which is to be multiplied by
  # the its stoichiometry to obtain Δ contribution.)

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
  alias α_for_TSr action_vector_for_TSr

  # Action vector for timed rateless stoichiometric transitions
  # By calling this method, the caller asserts that all timeless transitions
  # in this simulation are stoichiometric (or error is raised).
  # 
  def action_vector_for_Tr( Δt )
    return action_vector_for_TSr( Δt ) if TSr_transitions().empty?
    raise "The simulation also contains nonstoichiometric timed rateless " +
      "transitions! Consider using #action_vector_for_TSr."
  end
  alias α_for_Tr action_vector_for_Tr

  # Computes delta state for TSr transitions, given a Δt.
  # 
  def Δ_for_TSr( Δt )
    S_for_TSr() * action_vector_for_TSr( Δt )
  end

  # ==== Regarding sR transitions
  # 
  # (Whether nonstoichiometric or stoichiometric, transitions with rate
  # explicitly provide their contribution to the the state differential,
  # rather than just contribution to the Δ state.)

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

  # While for sR transitions, state differential is what matters the most,
  # as a conveniece, this method for multiplying the differential by provided
  # Δt is added.
  # 
  def Δ_Euler_for_sR( Δt )
    gradient_for_sR * Δt
  end
  alias Δ_euler_for_sR Δ_Euler_for_sR

  # ==== Regarding SR_transitions
  # 
  # (Whether nonstoichiometric or stoichiometric, transitions with rate
  # explicitly provide their contribution to the the state differential,
  # rather than just contribution to the Δ state.)

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
      "simulation are SR transitions."
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
    S_for_SR() * flux_vector_for_SR
  end

  # State differential for SR transitions as a hash { place_name: ∂ / ∂ᴛ }.
  # 
  def ∂_SR
    free_pp :gradient_for_SR
  end

  # Action vector for SR transitions under an assumption of making an Euler
  # step, whose size is given by the Δt argument.
  # 
  def Euler_action_vector_for_SR( Δt )
    flux_vector_for_SR * Δt
  end
  alias euler_action_vector_for_SR Euler_action_vector_for_SR
  alias Euler_α_for_SR Euler_action_vector_for_SR
  alias euler_α_for_SR Euler_action_vector_for_SR

  # Euler action fro SR transitions as an array.
  # 
  def Euler_action_for_SR( Δt )
    Euler_action_vector_for_SR( Δt ).column( 0 ).to_a
  end
  alias euler_action_for_SR Euler_action_for_SR

  # Convenience calculator of Δ state for SR transitions, assuming a single
  # Euler step with Δt given as argument.
  # 
  def Δ_Euler_for_SR( Δt )
    gradient_for_SR * Δt
  end
  alias Δ_euler_for_SR Δ_Euler_for_SR

  # Δ state for SR transitions, assuming Euler step with Δt as the argument,
  # returned as an array.
  # 
  def Δ_Euler_array_for_SR( Δt )
    Δ_Euler_for_SR( Δt ).column( 0 ).to_a
  end
  alias Δ_euler_array_for_SR Δ_Euler_array_for_SR


  # ==== Regarding A transitions
  # 
  # (Assignment transitions directly replace the values in their codomain
  # places with their results.)

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

  # Correspondence matrix free places => all places.
  # 
  attr_reader :F2A

  # Correspondence matrix clamped places => all places.
  # 
  attr_reader :C2A

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

  # This helper method takes a collection, a variable number of other arguments
  # and an optional block, and returns a hash whose keys are the collection
  # members, and whose values are given by the supplied othe arguments and/or
  # block in the following way: If there is no additional argument, but a block
  # is supplied, this is applied to the collection. If there is exactly one
  # other argument, and it is also a collection, it is used as values.
  # Otherwise, these other arguments are treated as a message to be sent to
  # self (via #send), expecting it to return a collection to be used as hash
  # values. Optional block (which is always assumed to be unary) can be used
  # to additionally modify the second collection.
  # 
  def zip_to_hash collection, *args, &block
    sz = args.size
    values = if sz == 0 then collection
             elsif sz == 1 && args[0].respond_to?( :each ) then args[0]
             else send *args end
    Hash[ collection.zip( block ? values.map( &block ) : values ) ]
  end

  # Chicken approach towards ensuring that transitions in question come in
  # the same order as in @transitions local variable. Takes a symbol as the
  # argument (:SR, :TSr, :sr etc.)
  # 
  def sift_from_net type_of_transitions
    from_net = net.send type_of_transitions
    @transitions.select { |t| from_net.include? t }
  end

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
    # this i
    @marking_vector += F2A() * Δ_free_places
  end

  # Fires all assignment transitions once.
  # 
  def assignment_transitions_all_fire!
    assignment_closures_for_A.each do |closure|
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
        λ {
          domain_marking = ( p2d * marking_vector ).column_to_a
          # I. TODO: t.domain_guard.( domain_marking )
          codomain_change = Array t.action_closure.( *domain_marking )
          # II. TODO: t.action_guard.( codomain_change )
          c2f * codomain_change
        }
      else
        λ { c2f * t.action_closure.( *( p2d * marking_vector ).column_to_a ) }
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
      λ { |Δt| c2f * t.action_closure.( Δt, *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_action_closures_for_tS
    tS_transitions.map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      λ { t.action_closure.( *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_action_closures_for_TSr
    TSr_transitions().map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      λ { |Δt| t.action_closure.( Δt, *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_rate_closures_for_sR
    sR_transitions.map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      λ { c2f * t.rate_closure.( *( p2d * marking_vector ).column_to_a ) }
    }
  end

  def create_rate_closures_for_SR
    SR_transitions().map{ |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      puts "Marking is #{pp :marking rescue nil}" if YPetri::DEBUG
      λ { t.rate_closure.( *( p2d * marking_vector ).column_to_a ) }
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
      λ {
        action = Array t.action_closure.( *( p2d * marking_vector ).column_to_a )
        assign = assignment_addresses.zip( action )
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
  def dup( **oo )
    self.class.new( oo.reverse_merge!( { method: @method,
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
