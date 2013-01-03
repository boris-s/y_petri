#encoding: utf-8
module YPetri

  # Emphasizing separation of concerns, the model is defined as agnostic of
  # simulation settings. Only for the purpose of simulation, model is combined
  # together with specific simulation settings. Simulation settings consist of
  # global settings (eg. time step, sampling rate...) and object specific
  # settings (eg. clamps, constraints...). Again, clamps and constraints *do not*
  # belong to the model. Simulation methods are also concern of this class, not
  # the model class. Thus, simulation is not done by calling instance methods of
  # the model. Instead, this class makes a 'mental image' of the model and only
  # that is used for actual simulation.
  #
  class Simulation
    SAMPLING_DECIMAL_PLACES = 5
    
    # Exposing @recording
    # 
    attr_reader :recording
    alias :r :recording

    # Simulation settings.
    # 
    def settings; nil end
    alias :simulation_settings :settings

    def recording_csv_string
      CSV.generate do |csv|
        @recording.keys.zip( @recording.values ).map{ |a, b| [ a ] + b.to_a }
          .each{ |line| csv << line }
      end        
    end

    # Currently, a simlation is largely immutable. It means that the net,
    # initial marking, clamps and simulation settings have to be supplied
    # upon initialization, whereupon the simulation forms their "mental
    # image", which does not change anymore, regardless of what happens
    # to the original net and other objects. Required constructor parameters
    # are :net, :place_clamps (alias :marking_clamps) and :initial_marking
    # (alias :initial_marking_vector). (Simulation subclasses may require
    # other arguments in addition to the ones just named.)
    # 
    def initialize *args; oo = args.extract_options!
      puts "starting to set up Simulation" if DEBUG

      oo.must_have :net do |o| o.class_complies? ::YPetri::Net end
      oo.may_have :place_clamps, syn!: :marking_clamps
      oo.may_have :initial_marking, syn!: :initial_marking_vector

      # === Net
      # 
      # Currently, @net is immutable within Simulation class.
      @net = oo[:net].dup
      @places = @net.places.dup
      @transitions = @net.transitions.dup

      self.singleton_class.class_exec {
        define_method :Place do net.send :Place end
        define_method :Transition do net.send :Transition end
        define_method :Net do net.send :Net end
        private :Place, :Transition, :Net
      }

      puts "setup of :net mental image complete" if DEBUG

      # === Simulation parameters
      # 
      # From Simulation's point of view, there are 2 kinds of places: free and
      # clamped. For free places, initial value has to be specified. For clamped
      # places, clamps have to be specified. Both (initial values and clamps) are
      # expected as hash type named parameters:
      @place_clamps = ( oo[:place_clamps] || {} )
        .with_keys do |key| place( key ) end
      @initial_marking = ( oo[:initial_marking] || {} )
        .with_keys do |key| place( key ) end

      # Enforce that keys in the hashes must be unique:
      @place_clamps.keys.aT_equal @place_clamps.keys.uniq
      @initial_marking.keys.aT_equal @initial_marking.keys.uniq

      puts "setup of clamps and initial marking done" if DEBUG

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
      places.each { |place|
        puts "Checking consistency of place #{place.name}"
        place.tE "have either clamp or initial marking",
                 "place #{p}" do |place|
          @place_clamps.keys.include?( place ) ||
            @initial_marking.keys.include?( place )
        end
      }

      puts "consistency check for clamps and initial marking passed" if DEBUG

      # --- free pl. => pl. matrix ----
      # multiplying this matrix by a marking vector for free places gives
      # corresponding marking vector for all places; used for marking update
      @free_places_to_all_places_matrix =
        Matrix.correspondence_matrix( free_places, places )
      @clamped_places_to_all_places_matrix =
        Matrix.correspondence_matrix( clamped_places, places )

      puts "correspondence matrices set up" if DEBUG

      # --- Stoichiometry matrices ----
      @stoichiometry_matrix_for_timeless_stoichiometric_transitions =
        create_stoichiometry_matrix_for( timeless_stoichiometric_transitions )
      @stoichiometry_matrix_for_stoichiometric_transitions_with_rate =
        create_stoichiometry_matrix_for( stoichiometric_transitions_with_rate )
      @stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions =
        create_stoichiometry_matrix_for( timed_rateless_stoichiometric_transitions )

      puts "stoichiometry matrices set up" if DEBUG

      # ----- Create other assets -----
      @delta_state_closures_for_timeless_nonstoichiometric_transitions =
        create_delta_state_closures_for_timeless_nonstoichiometric_transitions
      @delta_state_closures_for_timed_rateless_nonstoichiometric_transitions =
        create_delta_state_closures_for_timed_rateless_nonstoichiometric_transitions
      @action_closures_for_timeless_stoichiometric_transitions =
        create_action_closures_for_timeless_stoichiometric_transitions
      @action_closures_for_timed_rateless_stoichiometric_transitions =
        create_action_closures_for_timed_rateless_stoichiometric_transitions
      @rate_closures_for_nonstoichiometric_transitions_with_rate =
        create_rate_closures_for_nonstoichiometric_transitions_with_rate
      @rate_closures_for_stoichiometric_transitions_with_rate =
        create_rate_closures_for_stoichiometric_transitions_with_rate


      @zero_column_vector_sized_as_free_places =
        Matrix.zero( free_places.size, 1 )

      puts "other assets set up, about to reset" if DEBUG

      # ----------- Reset -------------
      reset!

      puts "reset complete" if DEBUG
    end

    # Exposing @net
    # 
    attr_reader :net

    # Exposing @places (array of instances)
    # 
    attr_reader :places, :transitions

    # Without parameters, it behaves as #places. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of places, and which
    # are then presented as hash { place_instance => object }.
    # 
    def places_ *aa, &b
      aa.empty? && b.nil? ? places : Hash[ places.zip( send *aa, &b ) ]
    end
    
    # Exposing @transitions (array of instances)
    # 
    attr_reader :transitions

    # Without parameters, it behaves as #transitions. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of transitions, and
    # which are then presented as hash { transition_instance => object }.
    # 
    def transitions_ *aa, &b
      aa.empty? && b.nil? ? transitions : Hash[ transitions.zip( send *aa, &b ) ]
    end

    # Array of place names.
    # 
    def pp; places.map &:name end

    # Without parameters, it behaves as #pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of places, and which
    # are then presented as hash { place_name => object }. Place instances
    # are used as hash keys for nameless places.
    # 
    def pp_ *aa, &b
      if aa.empty? and b.nil? then pp else
        Hash[ places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Array of transition names.
    # 
    def tt; transitions.map &:name end

    # Without parameters, it behaves as #tt. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of transitions, and
    # which are then presented as hash { transition_name => object }.
    # Transition instances are used as hash keys for nameless transitions.
    # 
    def tt_ *aa, &b
      if aa.empty? and b.nil? then tt else
        Hash[ transitions.map { |t| t.name.nil? ? t : t.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Exposing @place_clamps (hash with place instances as keys).
    # 
    attr_reader :place_clamps

    # Exposing @p_clamps (hash with place name symbols as keys)
    # 
    def p_clamps
      place_clamps.with_keys { |k| k.name.nil? ? k : k.name.to_sym }
    end

    # Free places (array of instances).
    # 
    def free_places; places.select { |p| @initial_marking.keys.include? p } end

    # Without parameters, it behaves as #free_places. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of free places, and which
    # are then presented as hash { place_instance => object }.
    # 
    def free_places_ *aa, &b
      aa.empty? && b.nil? ? free_places :
        Hash[ free_places.zip( send *aa, &b ) ]
    end

    # Clamped places (array of instances).
    # 
    def clamped_places; places.select { |p| @place_clamps.keys.include? p } end

    # Without parameters, it behaves as #clamped_places. If parameters are
    # given, these are treated as a message to be sent to self (as #send
    # method parameters), with the return value expected to be a collection
    # of objects, whose number is the same as the number of clamped places,
    # and which are then presented as hash { place_instance => object }.
    # 
    def clamped_places_ *aa, &b
       aa.empty? && b.nil? ? clamped_places :
        Hash[ clamped_places.zip( send *aa, &b ) ]
    end

    # Free places (array of instance names).
    # 
    def free_pp; free_places.map &:name end

    # Without parameters, it behaves as #free_pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of free places, and which
    # are then presented as hash { place_instance_name => object }. Place
    # instances are used as keys for nameless places.
    # 
    def free_pp_ *aa, &b
      if aa.empty? and b.nil? then free_pp else
        Hash[ free_places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Clamped places (array of instance names).
    # 
    def clamped_pp *aa; clamped_places.map &:name end

    # Without parameters, it behaves as #clamped_pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of clamped places, and
    # which are then presented as hash { place_instance_name => object }. Place
    # instances are used as keys for nameless places.
    # 
    def clamped_pp_ *aa, &b
      if aa.empty? and b.nil? then clamped_pp else
        Hash[ clamped_places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Exposing @initial_marking (hash with place instances as keys).
    # 
    attr_accessor :initial_marking

    # Initial marking hash with place name symbols as keys.
    # 
    def im
      initial_marking.with_keys { |k| k.name.nil? ? k : k.name.to_sym }
    end

    # Initial marking as array corresponding to free places.
    # 
    def initial_marking_array; free_places.map { |p| initial_marking[p] } end

    # Initial marking as a column vector corresponding to free places.
    # 
    def initial_marking_vector; Matrix.column_vector initial_marking_array end
    alias :iᴍ :initial_marking_vector

    # Marking of free places as an array.
    # 
    def marking_array; marking_vector.column( 0 ).to_a end
    alias :marking_array_of_free_places :marking_array

    # Marking of free places as a hash with place instances as keys.
    # 
    def marking; Hash[ free_places.zip( marking_array ) ] end

    # Marking of free places as a hash with place names as keys.
    # 
    def m
      Hash[ free_pp.map{|e| e.to_sym rescue nil }.zip( marking_array ) ]
    end
    alias :m_free :m

    # Marking of free places as a column vector.
    # 
    def marking_vector
      free_places_to_all_places_matrix.t * @marking_vector
    end
    alias :ᴍ :marking_vector
    alias :marking_vector_of_free_places :marking_vector
    alias :ᴍ_free :marking_vector

    # Marking of clamped places as an array.
    # 
    def marking_array_of_clamped_places
      marking_vector_of_clamped_places.column( 0 ).to_a
    end

    # Marking of clamped places as a hash with place instances as keys.
    # 
    def marking_of_clamped_places
      Hash[ clamped_places.zip( marking_array_of_clamped_places ) ]
    end

    # Marking of clamped places as a hash with place names as keys.
    # 
    def m_clamped
      Hash[ clamped_pp.map{|e| e.to_sym rescue nil }
              .zip( marking_array_of_clamped_places ) ]
    end

    # Marking of clamped places as a column vector.
    # 
    def marking_vector_of_clamped_places
      clamped_places_to_all_places_matrix.t * @marking_vector
    end
    alias :ᴍ_clamped :marking_vector_of_clamped_places

    # Marking array for all places.
    # 
    def marking_array_of_all_places; marking_vector!.column( 0 ).to_a end
    alias :marking_array! :marking_array_of_all_places

    # Marking of all places as a hash with place instances as keys.
    # 
    def marking_of_all_places; Hash[ places.zip( marking_array! ) ] end
    alias :marking! :marking_of_all_places

    # Marking of all places as a hash with place names as keys.
    # 
    def m_all; Hash[ pp.map{|e| e.to_sym rescue nil }
                       .zip( marking_array! ) ]
    end
    alias :m! :m_all

    # Marking of all places as a column vector.
    # 
    def marking_vector_of_all_places; @marking_vector end
    alias :marking_vector! :marking_vector_of_all_places
    alias :ᴍ_all :marking_vector_of_all_places
    alias :ᴍ! :marking_vector_of_all_places

    # Creation of stoichiometry matrix for an arbitrary array of stoichio.
    # transitions, that maps (has the number of rows equal to) the free places.
    # 
    def create_stoichiometry_matrix_for( array_of_S_transitions )
      array_of_S_transitions.map { |t| sparse_stoichiometry_vector( t ) }
        .reduce( Matrix.empty( free_places.size, 0 ), :join_right )
    end
    alias :create_S_for :create_stoichiometry_matrix_for
    alias :stoichiometry_matrix_for :create_stoichiometry_matrix_for
    alias :S_for :create_stoichiometry_matrix_for

    # Creation of stoichiometry matrix for an arbitrary array of stoichio.
    # transitions, that maps (has the number of rows equal to) all the places.
    # 
    def create_stoichiometry_matrix_for! array_of_S_transitions
      array_of_S_transitions.map { |t| sparse_stoichiometry_vector! t }
        .reduce( Matrix.empty( places.size, 0 ), :join_right )
    end
    alias :create_S_for! :create_stoichiometry_matrix_for!
    alias :stoichiometry_matrix_for! :create_stoichiometry_matrix_for!
    alias :S_for! :create_stoichiometry_matrix_for!

    # 3. Stoichiometry matrix for timeless stoichiometric transitions.
    # 
    attr_reader :stoichiometry_matrix_for_timeless_stoichiometric_transitions
    alias :stoichiometry_matrix_for_tS_transitions \
          :stoichiometry_matrix_for_timeless_stoichiometric_transitions
    alias :S_for_tS_transitions \
          :stoichiometry_matrix_for_timeless_stoichiometric_transitions

    # 4. Stoichiometry matrix for timed rateless stoichiometric transitions.
    # 
    attr_reader :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions
    alias :stoichiometry_matrix_for_TSr_transitions \
          :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions
    alias :S_for_TSr_transitions \
          :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions

    # 6. Stoichiometry matrix for stoichiometric transitions with rate.
    # 
    attr_reader :stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    alias :stoichiometry_matrix_for_SR_transitions \
          :stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    alias :S_for_SR_transitions \
          :stoichiometry_matrix_for_stoichiometric_transitions_with_rate

    # Stoichiometry matrix for stoichiometric transitions with rate.
    # By calling this method, the caller asserts that there are only
    # stoichiometric transitions with rate in the simulation (or error).
    # 
    def stoichiometry_matrix!
      txt = "The simulation contains also non-stoichiometric transitions. " +
            "Use method #stoichiometry_matrix_for_stoichiometric_transitions."
      raise txt unless s_transitions.empty? && r_transitions.empty?
      return stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    end
    alias :S! :stoichiometry_matrix!

    # ==== Exposing the collection of 1. ts transitions

    # Array of ts transitions.
    # 
    def timeless_nonstoichiometric_transitions
      from_net = net.timeless_nonstoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :ts_transitions :timeless_nonstoichiometric_transitions

    # Hash mapper for #ts_transitions (see #transitions_ method description).
    # 
    def timeless_nonstoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then ts_transitions else
        Hash[ ts_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :ts_transitions_ :timeless_nonstoichiometric_transitions_

    # Array of ts transition names.
    # 
    def timeless_nonstoichiometric_tt
      timeless_nonstoichiometric_transitions.map &:name
    end
    alias :ts_tt :timeless_nonstoichiometric_tt

    # Hash mapper for #ts_tt (see #tt_ method description).
    # 
    def timeless_nonstoichiometric_tt_ *aa, &b
      if aa.empty? && b.nil? then ts_tt else
        Hash[ ts_transitions
                .map { |t| t.name.nil? ? t : t.name }
                .zip( send *aa, &b ) ]
      end
    end
    alias :ts_tt_ :timeless_nonstoichiometric_tt_

    # ==== Exposing the collection of 2. tS transitions

    # Array of tS transitions.
    # 
    def timeless_stoichiometric_transitions
      from_net = net.timeless_stoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :tS_transitions :timeless_stoichiometric_transitions

    # Hash mapper for #tS_transitions (see #transitions_ method description).
    # 
    def timeless_stoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then tS_transitions else
        Hash[ tS_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :tS_transitions_ :timeless_nonstoichiometric_transitions_

    # Array of tS transition names.
    # 
    def timeless_stoichiometric_tt
      timeless_stoichiometric_transitions.map &:name
    end
    alias :tS_tt :timeless_stoichiometric_tt

    # Hash mapper for #tS_tt (see #tt_ method description).
    # 
    def timeless_stoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? tS_tt : Hash[ tS_tt.zip( send *aa, &b ) ]
    end
    alias :tS_tt_ :timeless_stoichiometric_tt_

    # ==== Exposing the collection of 3. Tsr transitions

    # Array of Tsr transitions.
    # 
    def timed_nonstoichiometric_transitions_without_rate
      from_net = net.timed_rateless_nonstoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :timed_rateless_nonstoichiometric_transitions \
          :timed_nonstoichiometric_transitions_without_rate
    alias :Tsr_transitions :timed_nonstoichiometric_transitions_without_rate

    # Hash mapper for #Tsr_transitions (see #transitions_ method description).
    # 
    def timed_nonstoichiometric_transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then self.Tsr_transitions else
        Hash[ self.Tsr_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_nonstoichiometric_transitions_ \
          :timed_nonstoichiometric_transitions_without_rate_
    alias :Tsr_transitions_ \
          :timed_nonstoichiometric_transitions_without_rate_

    # Array of Tsr transition names.
    # 
    def timed_nonstoichiometric_tt_without_rate
      timed_nonstoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_nonstoichiometric_tt \
          :timed_nonstoichiometric_tt_without_rate
    alias :Tsr_tt :timed_nonstoichiometric_tt_without_rate

    # Hash mapper for #Tsr_tt (see #tt_ method description).
    # 
    def timed_nonstoichiometric_tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? self.Tsr_transitions :
        Hash[ self.Tsr_transitions.zip( send *aa, &b ) ]
    end
    alias :timed_rateless_nonstoichiometric_tt_ \
          :timed_nonstoichiometric_transitions_without_rate_
    alias :Tsr_tt_ :timed_nonstoichiometric_tt_without_rate_

    # ==== Exposing the collection of 4. TSr transitions

    # Array of TSr transitions.
    # 
    def timed_stoichiometric_transitions_without_rate
      from_net = net.timed_rateless_stoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :timed_rateless_stoichiometric_transitions \
          :timed_stoichiometric_transitions_without_rate
    alias :TSr_transitions :timed_stoichiometric_transitions_without_rate

    # Hash mapper for #TSr_transitions (see #transitions_ method description).
    # 
    def timed_stoichiometric_transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then self.TSr_transitions else
        Hash[ self.TSr_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_stoichiometric_transitions_ \
          :timed_stoichiometric_transitions_without_rate_
    alias :TSr_transitions_ \
          :timed_stoichiometric_transitions_without_rate_

    # Array of TSr transition names.
    # 
    def timed_stoichiometric_tt_without_rate
      timed_stoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_stoichiometric_tt \
          :timed_stoichiometric_tt_without_rate
    alias :TSr_tt :timed_stoichiometric_tt_without_rate

    # Hash mapper for #TSr_tt (see #tt_ method description).
    # 
    def timed_stoichiometric_tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? self.TSr_tt :
        Hash[ self.TSr_tt.zip( send *aa, &b ) ]
    end
    alias :timed_rateless_stoichiometric_tt_ \
          :timed_stoichiometric_transitions_without_rate_
    alias :TSr_tt_ :timed_stoichiometric_tt_without_rate_

    # ==== Exposing the collection of 5. sR transitions

    # Array of sR transitions.
    # 
    def nonstoichiometric_transitions_with_rate
      from_net = net.nonstoichiometric_transitions_with_rate
      @transitions.select { |t| from_net.include? t }
    end
    alias :sR_transitions :nonstoichiometric_transitions_with_rate

    # Hash mapper for #sR_transitions (see #transitions_ method description).
    # 
    def nonstoichiometric_transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then sR_transitions else
        Hash[ sR_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :sR_transitions_ :nonstoichiometric_transitions_with_rate_

    # Array of sR transition names.
    # 
    def nonstoichiometric_tt_with_rate
      nonstoichiometric_transitions_with_rate.map &:name
    end
    alias :sR_tt :nonstoichiometric_tt_with_rate

    # Hash mapper for #sR_tt (see #tt_ method description).
    # 
    def nonstoichiometric_tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? sR_tt : Hash[ sR_tt.zip( send *aa, &b ) ]
    end
    alias :sR_tt_ :nonstoichiometric_tt_with_rate_

    # ==== Exposing the collection of 6. SR transitions

    # Array of SR transitions.
    #
    def stoichiometric_transitions_with_rate
      from_net = net.stoichiometric_transitions_with_rate
      @transitions.select { |t| from_net.include? t }
    end
    alias :SR_transitions :stoichiometric_transitions_with_rate

    # Hash mapper for #SR_transitions (see #transitions_ method description).
    # 
    def stoichiometric_transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then self.SR_transitions else
        Hash[ self.SR_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :SR_transitions_ :stoichiometric_transitions_with_rate_

    # Array of SR transition names.
    # 
    def stoichiometric_tt_with_rate
      stoichiometric_transitions_with_rate.map &:name
    end
    alias :SR_tt :stoichiometric_tt_with_rate

    # Hash mapper for #sR_tt (see #tt_ method description).
    # 
    def stoichiometric_tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? self.SR_tt :
        Hash[ self.SR_tt.zip( send *aa, &b ) ]
    end
    alias :SR_tt_ :stoichiometric_tt_with_rate_

    # ==== Exposing the collection of assignment (A) transitions

    # Array of transitions with explicit assignment action.
    # 
    def transitions_with_explicit_assignment_action
      from_net = net.transitions_with_explicit_assignment_action
      @transitions.select { |t| from_net.include? t }
    end
    alias :assignment_transitions :transitions_with_explicit_assignment_action
    alias :A_transitions :transitions_with_explicit_assignment_action

    # Hash mapper for #A_transitions (see #transitions_ method description).
    # 
    def transitions_with_explicit_assignment_action_ *aa, &b
      if aa.empty? && b.nil? then self.A_transitions else
        Hash[ self.A_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :A_transitions_ :transitions_with_explicit_assignment_action_
    alias :assignment_transitions_ :A_transitions_

    # Array of names of transitions with explicit assignment action.
    # 
    def tt_with_explicit_assignment_action
      transitions_with_explicit_assignment_action.map &:name
    end
    alias :assignment_tt :tt_with_explicit_assignment_action
    alias :A_tt :tt_with_explicit_assignment_action

    # Hash mapper for #A_tt (see #tt_ method description).
    # 
    def tt_with_explicit_assignment_action_ *aa, &b
      aa.empty? && b.nil? ? self.A_tt :
        Hash[ self.A_tt.zip( send *aa, &b ) ]
    end
    alias :assignment_tt_ :tt_with_explicit_assignment_action_
    alias :A_tt_ :tt_with_explicit_assignment_action_

    # ==== Stoichiometric transitions of any kind (S transitions)

    # Array of stoichiometric transitions (of any kind).
    # 
    def stoichiometric_transitions
      stoichio_from_net = net.stoichiometric_transitions
      @transitions.select{ |t| stoichio_from_net.include?( t ) }
    end
    alias :S_transitions :stoichiometric_transitions

    # Hash mapper for #S_transitions (see #transitions_ method description).
    # 
    def stoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then self.S_transitions else
        Hash[ self.S_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :S_transitions_ :stoichiometric_transitions_

    # Array of names of stoichiometric transitions (of any kind).
    # 
    def stoichiometric_tt; stoichiometric_transitions.map &:name end
    alias :S_tt :stoichiometric_tt

    # Hash mapper for #A_tt (see #tt_ method description).
    # 
    def stoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? self.S_tt : Hash[ self.S_tt.zip( send *aa, &b ) ]
    end
    alias :S_tt_ :stoichiometric_tt_

    # ==== Nonstoichiometric transitions of any kind (s transitions)

    # Array of nonstoichiometric transitions (of any kind).
    # 
    def nonstoichiometric_transitions
      non_stoichio_from_net = net.nonstoichiometric_transitions
      @transitions.select{ |t| non_stoichio_from_net.include?( t ) }
    end
    alias :s_transitions :nonstoichiometric_transitions

    # Hash mapper for #s_transitions (see #transitions_ method description).
    # 
    def nonstoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then s_transitions else
        Hash[ s_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :s_transitions_ :nonstoichiometric_transitions_

    # Array of names of nonstoichiometric transitions (of any kind).
    # 
    def nonstoichiometric_tt; nonstoichiometric_transitions.map &:name end
    alias :s_tt :nonstoichiometric_tt

    # Hash mapper for #s_tt (see #tt_ method description).
    # 
    def nonstoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? s_tt : Hash[ self.s_tt.zip( send *aa, &b ) ]
    end
    alias :s_tt_ :nonstoichiometric_tt_

    # ==== Transitions with rate (R transitions), otherwise of any kind

    # Array of transitions with rate (of any kind).
    # 
    def transitions_with_rate
      from_net = net.transitions_with_rate
      @transitions.select{ |t| from_net.include?( t ) }
    end
    alias :R_transitions :transitions_with_rate

    # Hash mapper for #R_transitions (see #transitions_ method description).
    # 
    def transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then self.R_transitions else
        Hash[ self.R_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :R_transitions_ :transitions_with_rate_

    # Array of names of transitions with rate (of any kind).
    # 
    def tt_with_rate; transitions_with_rate.map &:name end
    alias :R_tt :tt_with_rate

    # Hash mapper for #R_tt (see #tt_ method description).
    # 
    def tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? self.R_tt : Hash[ self.R_tt.zip( send *aa, &b ) ]
    end
    alias :R_tt_ :tt_with_rate_

    # ==== Rateless transitions (r transitions), otherwise of any kind

    # Array of rateless transitions (of any kind).
    # 
    def transitions_without_rate
      from_net = net.transitions_without_rate
      @transitions.select{ |t| from_net.include?( t ) }
    end
    alias :rateless_transitions :transitions_without_rate
    alias :r_transitions :transitions_without_rate

    # Hash mapper for #r_transitions (see #transitions_ method description).
    # 
    def transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then r_transitions else
        Hash[ r_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :rateless_transitions_ :transitions_without_rate_
    alias :r_transitions_ :transitions_without_rate_

    # Array of names of rateless transitions (of any kind).
    # 
    def tt_without_rate; transitions_without_rate.map &:name end
    alias :rateless_tt :tt_without_rate
    alias :r_tt :tt_without_rate

    # Hash mapper for #r_tt (see #tt_ method description).
    # 
    def tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? r_tt : Hash[ r_tt.zip( send *aa, &b ) ]
    end
    alias :rateless_tt_ :tt_without_rate_
    alias :r_tt_ :tt_without_rate_

    # === Methods presenting other simulation assets

    # ==== Timeless nonstoichiometric transitions (ts_transitions)

    # Exposing Δ state closures for ts transitions.
    # 
    attr_reader :delta_state_closures_for_timeless_nonstoichiometric_transitions
    alias :Δ_closures_for_ts_transitions \
          :delta_state_closures_for_timeless_nonstoichiometric_transitions

    # Δ state contribution if these ts transitions fire once. The closures
    # are called in their order, but the state update is not performed
    # between the calls (ie. they fire "simultaneously").
    # 
    def delta_state_if_timeless_nonstoichiometric_transitions_fire_once
      Δ_closures_for_ts_transitions.map( &:call )
        .reduce( @zero_column_vector_sized_as_free_places, :+ )
    end
    alias :Δ_if_timeless_nonstoichiometric_transitions_fire_once \
          :delta_state_if_timeless_nonstoichiometric_transitions_fire_once
    alias :Δ_if_ts_transitions_fire_once \
          :Δ_if_timeless_nonstoichiometric_transitions_fire_once

    # ==== Timed rateless nonstoichiometric transitions (Tsr_transitions).
    # Their closures do take Δt as argument, but do not expose their ∂
    # (or they might not even have one)

    # Exposing Δ state closures for Tsr transitions.
    # 
    attr_reader :delta_state_closures_for_timed_rateless_nonstoichiometric_transitions
    alias :Δ_closures_for_Tsr_transitions \
          :delta_state_closures_for_timed_rateless_nonstoichiometric_transitions

    # Δ state contribution for Tsr transitions given Δt.
    # 
    def delta_state_for_timed_rateless_nonstoichiometric_transitions( Δt )
      Δ_closures_for_Tsr_transitions.map { |cl| cl.( Δt ) }
        .reduce( @zero_column_vector_sized_as_free_places, :+ )
    end
    alias :Δ_for_timed_rateless_nonstoichiometric_transitions \
          :delta_state_for_timed_rateless_nonstoichiometric_transitions
    alias :Δ_for_Tsr_transitions \
          :delta_state_for_timed_rateless_nonstoichiometric_transitions

    # ==== Timeless stoichiometric transitions (tS_transitions)
    # These transitions are timeless, but stoichiometric. It means that
    # their closures do not output Δ state contribution directly, but instead
    # they output a single number, which is a transition action, and Δ state
    # is then computed from it by muliplying the the action vector with the
    # stoichiometric matrix.

    # Exposing action closures for tS transitions.
    # 
    attr_reader :action_closures_for_timeless_stoichiometric_transitions
    alias :action_closures_for_tS_transitions \
          :action_closures_for_timeless_stoichiometric_transitions

    # Action vector for if tS transitions fire once. The closures are called
    # in their order, but the state update is not performed between the
    # calls (ie. they fire "simultaneously").
    # 
    def action_vector_for_timeless_stoichiometric_transitions
      Matrix.column_vector action_closures_for_tS_transitions.map( &:call )
    end
    alias :action_vector_for_tS_transitions \
          :action_vector_for_timeless_stoichiometric_transitions
    alias :α_for_tS_transitions \
          :action_vector_for_timeless_stoichiometric_transitions

    # Action vector if tS transitions fire once, like the previous method.
    # But by calling this method, the caller asserts that all timeless
    # transitions in this simulation are stoichiometric (or error is raised).
    # n
    def action_vector_for_timeless_transitions!
      txt = "The simulation also contains nonstoichiometric timeless " +
        "transitions. Consider using " +
        "#action_vector_for_timeless_stoichiometric_transitions."
      raise txt unless timeless_nonstoichiometric_transitions.empty?
      action_vector_for_timeless_stoichiometric_transitions
    end
    alias :action_vector_for_t_transitions! \
          :action_vector_for_timeless_transitions!
    alias :α_for_t_transitions! :action_vector_for_timeless_transitions!

    # Δ state contribution for tS transitions.
    # 
    def delta_state_if_timeless_stoichiometric_transitions_fire_once
      self.S_for_tS_transitions * action_vector_for_tS_transitions
    end
    alias :Δ_if_timeless_stoichiometric_transitions_fire_once \
          :delta_state_if_timeless_stoichiometric_transitions_fire_once
    alias :Δ_if_tS_transitions_fire_once \
          :Δ_if_timeless_stoichiometric_transitions_fire_once

    # ==== Timed rateless stoichiometric transitions (TSr_transitions)
    # Same as Tsr transitions, but stoichiometric - their closures do not
    # return Δ contribution, but transition action, that has to be
    # multiplied with the stoichiometry vector tor obtain Δ contribution.

    # Exposing action closures for TSr transitions.
    # 
    attr_reader :action_closures_for_timed_rateless_stoichiometric_transitions
    alias :action_closures_for_TSr_transitions \
          :action_closures_for_timed_rateless_stoichiometric_transitions

    # By calling this method, the caller asserts that all timeless transitions
    # in this simulation are stoichiometric (or error is raised).
    # 
    def action_closures_for_timed_rateless_transitions!
      txt = "The simulation also contains nonstoichiometric timed rateless " +
        "transitions. Consider using " +
        "#action_closures_for_timed_rateless_stoichiometric_transitions."
      raise txt unless timed_rateless_stoichiometric_transitions.empty?
      action_closures_for_timed_rateless_stoichiometric_transitions
    end
    alias :action_closures_for_Tr_transitions! \
          :action_closures_for_timed_rateless_transitions!

    # Action vector for timed rateless stoichiometric transitions.
    # 
    def action_vector_for_timed_rateless_stoichiometric_transitions( Δt )
      Matrix.column_vector action_closures_for_TSr_transitions
        .map { |cl| cl.( Δt ) }
    end
    alias :action_vector_for_TSr_transitions \
          :action_vector_for_timed_rateless_stoichiometric_transitions
    alias :α_for_TSr_transitions \
          :action_vector_for_timed_rateless_stoichiometric_transitions

    # Action vector for timed rateless stoichiometric transitions
    # By calling this method, the caller asserts that all timeless transitions
    # in this simulation are stoichiometric (or error is raised).
    # 
    def action_vector_for_timed_rateless_transitions!( Δt )
      txt = "The simulation also contains nonstoichiometric timed rateless " +
        "transitions. Consider using " +
        "#action_vector_for_timed_rateless_stoichiometric_transitions."
      raise txt unless timed_rateless_stoichiometric_transitions.empty?
      action_vector_for_timed_rateless_stoichiometric_transitions( Δt )
    end
    alias :action_vector_for_Tr_transitions! \
          :action_vector_for_timed_rateless_transitions!
    alias :α_for_Tr_transitions! :action_vector_for_Tr_transitions!

    # Computes Δ state for TSr transitions, given a Δt.
    # 
    def delta_state_for_timed_rateless_stoichiometric_transitions( Δt )
      self.S_for_TSr_transitions * action_vector_for_TSr_transitions( Δt )
    end
    alias :Δ_for_timed_rateless_stoichiometric_transitions \
          :delta_state_for_timed_rateless_stoichiometric_transitions
    alias :Δ_for_TSr_transitions \
          :delta_state_for_timed_rateless_stoichiometric_transitions

    # ==== Nonstoichiometric transitions with rate (sR_transitions)
    # Whether nonstoichiometric, or stoichiometric, transitions with rate
    # explicitly provide their contribution to the the state differential,
    # rather than just contribution to the Δ state.

    # Exposing rate closures for sR transitions.
    # 
    attr_reader :rate_closures_for_nonstoichiometric_transitions_with_rate
    alias :rate_closures_for_sR_transitions \
          :rate_closures_for_nonstoichiometric_transitions_with_rate

    # Rate closures for sR transitions.
    # By calling this method, the caller asserts that there are no rateless
    # transitions in the simulation (or error is raised).
    # 
    def rate_closures_for_nonstoichiometric_transitions!
      raise "The simulation also contains rateless transitions. " +
        "Consider using " +
        "#rate_closures_for_stoichiometric_transitions_with_rate" unless
        rateless_transitions.empty?
      rate_closures_for_sR_transitions
    end
    alias :rate_closures_for_s_transitions! \
          :rate_closures_for_nonstoichiometric_transitions!

    # State differential for sR transitions.
    # 
    def state_differential_for_nonstoichiometric_transitions_with_rate
      rate_closures_for_sR_transitions.map( &:call )
        .reduce( @zero_column_vector_sized_as_free_places, :+ )
    end
    alias :state_differential_for_sR_transitions \
          :state_differential_for_nonstoichiometric_transitions_with_rate
    alias :∂_for_nonstoichiometric_transitions_with_rate \
          :state_differential_for_nonstoichiometric_transitions_with_rate
    alias :∂_for_sR_transitions \
          :∂_for_nonstoichiometric_transitions_with_rate

    # While for sR transitions, state differential is what matters the most,
    # as a conveniece, this method for multiplying the differential by
    # provided Δt is added.
    # 
    def delta_state_Euler_for_nonstoichiometric_transitions_with_rate( Δt )
      ∂_for_sR_transitions * Δt
    end
    alias :delta_state_euler_for_nonstoichiometric_transitions_with_rate \
          :delta_state_Euler_for_nonstoichiometric_transitions_with_rate
    alias :Δ_Euler_for_nonstoichiometric_transitions_with_rate \
          :delta_state_Euler_for_nonstoichiometric_transitions_with_rate
    alias :Δ_euler_for_nonstoichiometric_transitions_with_rate \
          :Δ_Euler_for_nonstoichiometric_transitions_with_rate
    alias :Δ_Euler_for_sR_transitions \
          :Δ_Euler_for_nonstoichiometric_transitions_with_rate
    alias :Δ_euler_for_sR_transitions :Δ_Euler_for_sR_transitions

    # ==== Stoichiometric transitions with rate (SR_transitions)
    # Whether nonstoichiometric, or stoichiometric, transitions with rate
    # explicitly provide their contribution to the the state differential,
    # rather than just contribution to the Δ state.

    # Exposing rate closures for SR transitions.
    # 
    attr_reader :rate_closures_for_stoichiometric_transitions_with_rate
    alias :rate_closures_for_SR_transitions \
          :rate_closures_for_stoichiometric_transitions_with_rate

    # Rate closures for SR transitions.
    # By calling this method, the caller asserts that there are no rateless
    # transitions in the simulation (or error is raised).
    # 
    def rate_closures_for_stoichiometric_transitions!
      txt = "The simulation also contains rateless transitions. Consider " +
        "using #rate_closures_for_stoichiometric_transitions_with_rate"
      raise txt unless rateless_transitions.empty?
      rate_closures_for_SR_transitions
    end
    alias :rate_closures_for_S_transitions! \
          :rate_closures_for_stoichiometric_transitions!

    # Rate closures for SR transitions.
    # By calling this method, the caller asserts that there are only
    # stoichiometric transitions with rate in the simulation (or error).
    # 
    def rate_closures!
      raise "The simulation contains also nonstoichiometric transitions. " +
        "Consider using #rate_closures_for_stoichiometric_transitions" unless
        nonstoichiometric_transitions.empty?
      rate_closures_for_S_transitions!
    end

    # While rateless stoichimetric transitions provide transition action as
    # their closure output, SR transitions' clousures return flux, which is
    # ∂action / ∂t. This methods return flux for SR transitions as a column
    # vector.
    # 
    def flux_vector_for_stoichiometric_transitions_with_rate
      Matrix.column_vector( rate_closures_for_SR_transitions.map( &:call ) )
    end
    alias :flux_vector_for_SR_transitions \
          :flux_vector_for_stoichiometric_transitions_with_rate
    alias :φ_for_stoichiometric_transitions_with_rate \
          :flux_vector_for_stoichiometric_transitions_with_rate
    alias :φ_for_SR_transitions \
          :flux_vector_for_stoichiometric_transitions_with_rate

    # Flux vector for SR transitions. Same as the previous method, but
    # the caller asserts that there are only stoichiometric transitions
    # with rate in the simulation (or error).
    # 
    def flux_vector!
      raise "The simulation must contain only stoichiometric transitions " +
        "with rate!" unless s_transitions.empty? && r_transitions.empty?
      flux_vector_for_stoichiometric_transitions_with_rate
    end
    alias :φ! :flux_vector!

    # Flux of SR transitions as hash with transition name symbols as keys.
    # 
    def flux_for_SR_tt; self.SR_tt_ :flux_vector_for_SR_transitions end

    # Same as #flux_for_SR_tt, but with caller asserting that there are
    # none but SR transitions in the simulation (or error).
    # 
    def f!; self.SR_tt_ :flux_vector! end

    # State differential for SR transitions.
    # 
    def state_differential_for_stoichiometric_transitions_with_rate
      stoichiometry_matrix_for_SR_transitions * flux_vector_for_SR_transitions
    end
    alias :state_differential_for_SR_transitions \
          :state_differential_for_stoichiometric_transitions_with_rate
    alias :∂_for_stoichiometric_transitions_with_rate \
          :state_differential_for_SR_transitions
    alias :∂_for_SR_transitions :∂_for_stoichiometric_transitions_with_rate

    # Action vector for SR transitions under the assumption of making an
    # Eulerian step, with Δt provided as a parameter.
    # 
    def Euler_action_vector_for_stoichiometric_transitions_with_rate( Δt )
      flux_vector_for_SR_transitions * Δt
    end
    alias :euler_action_vector_for_stoichiometric_transitions_with_rate \
          :Euler_action_vector_for_stoichiometric_transitions_with_rate
    alias :Euler_action_vector_for_SR_transitions \
          :Euler_action_vector_for_stoichiometric_transitions_with_rate
    alias :euler_action_vector_for_SR_transitions \
          :Euler_action_vector_for_SR_transitions
    alias :Euler_α_for_stoichiometric_transitions_with_rate \
          :euler_action_vector_for_SR_transitions
    alias :Euler_α_for_SR_transitions \
          :euler_action_vector_for_SR_transitions
    alias :euler_α_for_SR_transitions \
          :euler_action_vector_for_SR_transitions

    # Euler action fro SR transitions as hash with tr. names as keys.
    # 
    def Euler_action_for_SR_tt( Δt )
      stoichiometric_tt_ :Euler_action_vector_for_SR_transitions, Δt
    end
    alias :euler_action_for_SR_tt :Euler_action_for_SR_tt

    # Convenience calculator of Δ state for SR transitions, assuming a single
    # Eulerian step with Δt given as parameter.
    # 
    def Δ_Euler_for_stoichiometric_transitions_with_rate( Δt )
      ∂_for_SR_transitions * Δt
    end
    alias :Δ_euler_for_stoichiometric_transitions_with_rate \
          :Δ_Euler_for_stoichiometric_transitions_with_rate
    alias :Δ_Euler_for_SR_transitions \
          :Δ_Euler_for_stoichiometric_transitions_with_rate
    alias :Δ_euler_for_SR_transitions :Δ_Euler_for_SR_transitions

    # Δ state for SR transitions under Eulerian step with Δt as parameter,
    # returning a hash with free place symbols as keys.
    # 
    def Δ_Euler_for_SR_tt( Δt )
      free_pp_ :Δ_Euler_for_SR_transitions, Δt
    end
    alias :Δ_euler_for_SR_tt :Δ_Euler_for_SR_tt

    # ==== Sparse stoichiometry vectors for transitions

    # For a transition specified by the argument, this method returns a sparse
    # stoichiometry vector mapped to free places of the simulation.
    # 
    def sparse_stoichiometry_vector transition
      t = transition( transition )
      raise AE, "Transition #{transition} not stoichiometric!" unless
        t.stoichiometric?
      Matrix.correspondence_matrix( t.codomain, free_places ) *
        Matrix.column_vector( t.stoichiometry )
    end
    alias :sparse_σ :sparse_stoichiometry_vector

    # For a transition specified by the argument, this method returns a sparse
    # stoichiometry vector mapped to all the places of the simulation.
    # 
    def sparse_stoichiometry_vector! transition
      t = transition( transition )
      raise AE, "Transition #{transition} not stoichiometric!" unless
        t.stoichiometric?
      Matrix.correspondence_matrix( t.codomain, places ) *
        Matrix.column_vector( t.stoichiometry )
    end
    alias :sparse_σ! :sparse_stoichiometry_vector!

    # Correspondence matrix free places => all places.
    # 
    attr_reader :free_places_to_all_places_matrix
    alias :f2p_matrix :free_places_to_all_places_matrix

    # Correspondence matrix clamped places => all places.
    # 
    attr_reader :clamped_places_to_all_places_matrix
    alias :c2p_matrix :clamped_places_to_all_places_matrix

    def inspect                      # :nodoc:
      "YPetri::Simulation[ #{places.size} places, " +
        "#{transitions.size} transitions, object id: #{object_id} ]"
    end

    def to_s                         # :nodoc:
      "Simulation[ #{pp.size} pp, #{tt.size} tt ]"
    end

    private

    # Resets the simulation
    # 
    def reset!
      puts "Starting #reset! method" if DEBUG
      zero_vector = Matrix.column_vector( places.map { Matrix::TOTAL_ZERO.new } ) # Float zeros
      puts "zero vector prepared" if DEBUG
      mv_clamped = compute_marking_vector_of_clamped_places
      puts "#reset! obtained marking vector of clamped places" if DEBUG
      clamped_2_all = clamped_places_to_all_places_matrix
      puts "#reset! obtained conversion matrix" if DEBUG
      clamped_component = clamped_2_all * mv_clamped
      puts "clamped component of marking vector prepared:\n#{clamped_component}" if DEBUG
      mv_free = compute_initial_marking_vector_of_free_places
      puts "#reset! obtained initial marking vector of free places" if DEBUG
      free_2_all = free_places_to_all_places_matrix
      puts "#reset! obtained conversion matrix" if DEBUG
      free_component = free_2_all * mv_free
      puts "free component of marking vector prepared:\n#{free_component}" if DEBUG
      @marking_vector = zero_vector + clamped_component + free_component
      puts "marking vector assembled\n#{m}\n, about to reset recording" if DEBUG
      reset_recording!
      puts "reset recording done, about to initiate sampling process" if DEBUG
      note_state_change!
      puts "sampling process initiated, #reset! done" if DEBUG
      return self
    end

    # Resets the recording
    # 
    def reset_recording!; @recording = {} end

    # To be called whenever the state changes. The method will cogitate, whether
    # the observed state change warrants calling #sample!
    # 
    def note_state_change!
      sample! # default for vanilla Simulation: sample! at every occasion
    end
    
    # Does sampling into @recording, which is a hash of pairs
    # { sampling_event => simulation state }
    # 
    def sample! key=ℒ(:sample!)
      @sample_number = @sample_number + 1 rescue 0
      @recording[ key.ℓ?(:sample!) ? @sample_number : key ] =
        marking_array!.map { |num| num.round SAMPLING_DECIMAL_PLACES }
    end

    # Called upon initialzation
    # 
    def compute_initial_marking_vector_of_free_places
      puts "computing the marking vector of free places" if DEBUG
      results = free_places.map { |p|
        im = @initial_marking[ p ]
        puts "doing free place #{p} with init. marking #{im}" if DEBUG
        # unwrap places / cells
        im = case im
             when Place then im.marking
             else im end
        case im
        when Proc then im.call
        else im end
      }
      # and create the matrix out of the results
      puts "about to create the column vector" if DEBUG
      cv = Matrix.column_vector results
      puts "column vector #{cv} prepared" if DEBUG
      return cv
    end

    # Called upon initialization
    # 
    def compute_marking_vector_of_clamped_places
      puts "computing the marking vector of clamped places" if DEBUG
      results = clamped_places.map { |p|
        clamp = @place_clamps[ p ]
        puts "doing clamped place #{p} with clamp #{clamp}" if DEBUG
        # unwrap places / cells
        clamp = case clamp
                when Place then clamp.marking
                else clamp end
        # unwrap closure by calling it
        case clamp
        when Proc then clamp.call
        else clamp end
      }
      # and create the matrix out of the results
      puts "about to create the column vector" if DEBUG
      cv = Matrix.column_vector results
      puts "column vector #{cv} prepared" if DEBUG
      return cv
    end

    # Expects a Δ marking vector for free places and performs the specified
    # change on the marking vector for all places.
    # 
    def update_marking! Δ_free_places
      @marking_vector += free_places_to_all_places_matrix * Δ_free_places
    end

    # ----------------------------------------------------------------------
    # Methods to create other instance assets upon initialization.
    # These instance assets are created at the beginning, so the work
    # needs to be performed only once in the instance lifetime.

    def create_delta_state_closures_for_timeless_nonstoichiometric_transitions
      timeless_nonstoichiometric_transitions.map { |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        c2f = Matrix.correspondence_matrix( t.codomain, free_places )
        λ { c2f * t.action_closure.( *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    def create_delta_state_closures_for_timed_rateless_nonstoichiometric_transitions
      timed_rateless_nonstoichiometric_transitions.map { |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        c2f = Matrix.correspondence_matrix( t.codomain, free_places )
        λ { |Δt| c2f * t.action_closure.( Δt, *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    def create_action_closures_for_timeless_stoichiometric_transitions
      timeless_stoichiometric_transitions.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { t.action_closure.( *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    def create_action_closures_for_timed_rateless_stoichiometric_transitions
      timed_rateless_stoichiometric_transitions.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { |Δt| t.action_closure.( Δt, *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    def create_rate_closures_for_nonstoichiometric_transitions_with_rate
      nonstoichiometric_transitions_with_rate.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        c2f = Matrix.correspondence_matrix( t.codomain, free_places )
        λ { c2f * t.rate_closure.( *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    def create_rate_closures_for_stoichiometric_transitions_with_rate
      stoichiometric_transitions_with_rate.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { t.rate_closure.( *( p2d * ᴍ! ).column_to_a ) }
      }
    end

    # Place, Transition, Net class
    # 
    def Place; ::YPetri::Place end
    def Transition; ::YPetri::Transition end

    # Instance identification methods.
    # 
    def place( which ); Place().instance( which ) end
    def transition( which ); Transition().instance( which ) end

    # LATER: Mathods for timeless simulation.
  end # class Simulation
end # module YPetri
