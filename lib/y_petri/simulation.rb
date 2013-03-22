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

  # Currently, a simulation instance is largely immutable. It means that
  # the net, initial marking, clamps and simulation settings have to be
  # supplied upon initialization, whereupon the simulation forms their
  # "mental image", which does not change anymore, regardless of what happens
  # to the original net and other objects. Required constructor parameters
  # are :net, :place_clamps (alias :marking_clamps) and :initial_marking
  # (alias :initial_marking_vector). (Simulation subclasses may require other
  # arguments in addition to the ones just named.)
  # 
  def initialize args={}
    puts "starting to set up Simulation" if YPetri::DEBUG

    args.may_have :method, syn!: :simulation_method
    args.must_have :net do |o| o.class_complies? ::YPetri::Net end
    args.may_have :place_clamps, syn!: :marking_clamps
    args.may_have :initial_marking, syn!: :initial_marking_vector

    # ==== Simulation method
    # 
    @method = args[:method] || default_simulation_method()

    # ==== Net
    # 
    @net = args[:net].dup # @immutable within the instance
    @places = @net.places.dup
    @transitions = @net.transitions.dup

    self.singleton_class.class_exec {
      define_method :Place do net.send :Place end
      define_method :Transition do net.send :Transition end
      define_method :Net do net.send :Net end
      private :Place, :Transition, :Net
    }

    puts "setup of :net mental image complete" if YPetri::DEBUG

    # ==== Simulation parameters
    # 
    # A simulation distinguishes between free and clamped places.  For free
    # places, initial value has to be specified. For clamped places, clamps
    # have to be specified. Both initial values and clamps are expected as
    # hash-type named parameters:
    @place_clamps = ( args[:place_clamps] || {} ).with_keys { |k| place k }
    @initial_marking = ( args[:initial_marking] || {} ).with_keys { |k| place k }

    # Enforce that keys in the hashes must be unique:
    @place_clamps.keys.aT_equal @place_clamps.keys.uniq
    @initial_marking.keys.aT_equal @initial_marking.keys.uniq

    puts "setup of clamps and initial marking done" if YPetri::DEBUG

    # === Consistency check
    # 
    # # Clamped places must not have explicit initial marking specified:
    # @place_clamps.keys.each { |place|
    #   place.aT_not "clamped place #{place}",
    #                "have explicitly specified initial marking" do |place|
    #     @initial_marking.keys.include? place
    #   end
    # }

    # Each place must be treated: either clamped, or have initial marking
    places.each { |p|
      p.aT "place #{p}", "have either clamp or initial marking" do |p|
        @place_clamps.keys.include?( p ) || @initial_marking.keys.include?( p )
      end
    }

    puts "consistency check for clamps and initial marking passed" if YPetri::DEBUG

    # === Correspondence matrices.

    # Multiplying this matrix by marking vector for free places (ᴍ) gives
    # ᴍ mapped for all places.
    @F2A = Matrix.correspondence_matrix( free_places, places )

    # Multiplying this matrix by marking vector for clamped places maps that
    # vector to all places.
    @C2A = Matrix.correspondence_matrix( clamped_places, places )

    puts "correspondence matrices set up" if YPetri::DEBUG

    # --- Stoichiometry matrices ----
    @S_for_tS = S_for tS_transitions()
    @S_for_SR = S_for SR_transitions()
    @S_for_TSr = S_for TSr_transitions()

    puts "stoichiometry matrices set up" if YPetri::DEBUG

    # ----- Create other assets -----
    @Δ_closures_for_ts = create_Δ_closures_for_ts
    @Δ_closures_for_Tsr = create_Δ_closures_for_Tsr
    @action_closures_for_tS = create_action_closures_for_tS
    @action_closures_for_TSr = create_action_closures_for_TSr
    @rate_closures_for_sR = create_rate_closures_for_sR
    @rate_closures_for_SR = create_rate_closures_for_SR

    @assignment_closures_for_A = create_assignment_closures_for_A

    @zero_ᴍ = Matrix.zero( free_places.size, 1 )

    puts "other assets set up, about to reset" if YPetri::DEBUG

    # ----------- Reset -------------
    reset!

    puts "reset complete" if YPetri::DEBUG
  end

  # Allows to explore the system at different state / time, while leaving
  # everything else as it was before. Accepts argument(s) telling it the
  # system state of interest, and returns a simulation instance with the
  # same parameters and settings as self, except for the different state.
  # 
  def at *args
    oo = args.extract_options!
    # TODO: acceptable options: :m, :ᴍ
    m = oo[:m]
    duplicate =
      self.class.new( { method: @method,
                        net: @net,
                        place_clamps: @place_clamps,
                        initial_marking: @initial_marking
                      }.update( simulation_settings ) )
    duplicate.send :set_recording, recording
    duplicate.send :set_marking, m
    return duplicate
  end

  # Exposing @net.
  # 
  attr_reader :net

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
    kk = @place_clamps.keys
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
  def place_clamps
    clamped_places.map { |p| @place_clamps[p] }
  end

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
    free_places :marking
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

  # Like #A_transitions, except that transition names are used instead of
  # instances, whenever possible.
  # 
  def A_tt *aa, &b
    return zip_to_hash A_tt(), *aa, &b unless aa.empty? && b.nil?
    A_transitions().map { |t| t.name || t }
  end

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
  attr_reader :Δ_closures_for_ts

  # Delta state contribution if ts transitions fire once. The closures
  # are called in their order, but the state update is not performed
  # between the calls (ie. they fire "simultaneously").
  # 
  def Δ_if_ts_fire_once
    Δ_closures_for_ts.map( &:call ).reduce( @zero_ᴍ, :+ )
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
    rate_closures_for_sR.map( &:call ).reduce( @zero_ᴍ, :+ )
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
    # zero_vector = Matrix.column_vector( places.map { SY::ZERO rescue 0 } ) # Float zeros
    zero_vector = Matrix.column_vector( places.map { 0 } ) # Float zeros
    puts "zero vector prepared" if YPetri::DEBUG
    mv_clamped = compute_marking_vector_of_clamped_places
    puts "#reset! obtained marking vector of clamped places" if YPetri::DEBUG
    clamped_component = C2A() * mv_clamped
    puts "clamped component of marking vector prepared:\n#{clamped_component}" if YPetri::DEBUG
    mv_free = compute_initial_marking_vector_of_free_places
    puts "#reset! obtained initial marking vector of free places" if YPetri::DEBUG
    free_component = F2A() * mv_free
    puts "free component of marking vector prepared:\n#{free_component}" if YPetri::DEBUG
    free_component.aT { |v|
      qnt = v.first.quantity rescue :no_quantity
      unless qnt == :no_quantity
        v.all? { |e| e.quantity == qnt }
      else true end
    }
    puts "free component of marking vector prepared:\n#{free_component}" if YPetri::DEBUG
    @marking_vector = zero_vector + clamped_component + free_component
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
  def sample! key=ℒ(:sample!)
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
      clamp = @place_clamps[ p ]
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

  def create_Δ_closures_for_ts
    ts_transitions.map { |t|
      p2d = Matrix.correspondence_matrix( places, t.domain )
      c2f = Matrix.correspondence_matrix( t.codomain, free_places )
      λ { c2f * t.action_closure.( *( p2d * marking_vector ).column_to_a ) }
    }
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
      lambda do
        # puts "result is #{result}"
        act = Array t.action_closure.( *( p2d * marking_vector ).column_to_a )
        # puts "assignment addresses are #{assignment_addresses}"
        # puts "act is #{act}"
        # puts "nils are #{nils}"
        assign = assignment_addresses.zip( act )
        # puts "assign is #{assign}"
        assign = assign.each_with_object nils.dup do |pair, o| o[pair[0]] = pair[1] end
        # puts "assign is #{assign}"
        @marking_vector.map { |original_marking|
          assignment_order = assign.shift
          assignment_order ? assignment_order : original_marking
        }
      end
    } # map
  end

  # Private method for resetting marking.
  # 
  def set_marking m_array
    @marking_vector = Matrix.column_vector( m_array )
  end

  # Private method for resetting recording.
  # 
  def set_recording rec
    @recording = Hash[ rec ]
  end

  # Place, Transition, Net class
  # 
  def Place; YPetri::Place end
  def Transition; YPetri::Transition end

  # Instance identification methods.
  # 
  def place( which ); Place().instance( which ) end
  def transition( which ); Transition().instance( which ) end

  # LATER: Mathods for timeless simulation.
end # class YPetri::Simulation
