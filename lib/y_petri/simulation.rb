#encoding: utf-8

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
module YPetri
  class Simulation
    SAMPLING_DECIMAL_PLACES = 5
    
    # Exposing @recording
    attr_reader :recording
    alias :r :recording

    # LATER: Mathods for timeless simulation.

    def print_recording
      CSV.generate do |csv|
        @recording.keys.zip( @recording.values ).map{ |a, b| [ a ] + b.to_a }
          .each{ |line| csv << line }
      end        
    end

    def initialize *aa; oo = aa.extract_options!
      # ------------ Net --------------
      # Currently, @net is immutable within Simulation class. In other words,
      # upon initialize, Simulation forms a 'mental image' of the net, which it
      # does not change anymore, regardless of what happens to the original net.
      @net = oo.must_have :net do |o| o.declares_module_compliance? Net end.dup
      @places, @transitions = @net.places.dup, @net.transitions.dup

      # ---- Simulation parameters ----
      # From Simulation's point of view, there are 2 kinds of places: free and
      # clamped. For free places, initial value has to be specified. For clamped
      # places, clamps have to be specified. Both (initial values and clamps) are
      # expected as hash type named parameters:
      @place_clamps =
        ( oo.may_have( :place_clamps, syn!: :marking_clamps ) || {} )
        .with_keys do |key| ::YPetri::Place( key ) end
      @initial_marking =
        ( oo.may_have( :initial_marking, syn!: :initial_marking_vector ) || {} )
        .with_keys do |key| ::YPetri::Place( key ) end
      [ @place_clamps, @initial_marking ].each { |hsh|
        hsh.aE_is_a Hash          # both are required to be hashes
        hsh.with_keys do |key|    # with places or place names as keys
          case key
          when Place then places.find { |p| p == key } or
              raise AE, "Place '#{key}' not in the simulated net."
          when String, Symbol then places.find { |p| p.name == key.to_s } or
              raise AE, "Place named '#{key}' not in the simulated net."
          else raise AE, "When specifying place clamps and initial marking," +
              "each key of the hash must be either a Place instance or a name"
          end
        end
        hsh.keys.aE_equal hsh.keys.uniq # keys must be unique
        hsh.values.aE_all_numeric    # values must be numeric (for now)
      } # each |hsh|

      # ------ Consistency check ------
      # Clamped place must not have initial marking:

      # FIXME: Commented out for now
      # @place_clamps.keys.each { |p|
      #   p.aE_not "clamped place #{p}", "have specified initial marking" do |p|
      #     @initial_marking.keys.include? p
      #   end
      # }

      # Each place must be treated: either clamped, or have initial marking
      places.each { |p|
        p.aE "have either clamp or initial marking", "place #{p}" do |p|
          @place_clamps.keys.include?( p ) || @initial_marking.keys.include?( p )
        end
      }

      # --- free pl. => pl. matrix ----
      # multiplying this matrix by a marking vector for free places gives
      # corresponding marking vector for all places; used for marking update
      @free_places_to_all_places_matrix =
        Matrix.correspondence_matrix( free_places, places )
      @clamped_places_to_all_places_matrix =
        Matrix.correspondence_matrix( clamped_places, places )

      # --- Stoichiometry matrices ----
      @stoichiometry_matrix_for_timeless_stoichiometric_transitions =
        create_stoichiometry_matrix_for( timeless_stoichiometric_transitions )
      @stoichiometry_matrix_for_stoichiometric_transitions_with_rate =
        create_stoichiometry_matrix_for( stoichiometric_transitions_with_rate )
      @stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions =
        create_stoichiometry_matrix_for( timed_rateless_stoichiometric_transitions )

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

      # ----------- Reset -------------
      reset!
    end

    # Exposing @net
    attr_reader :net

    # Exposing @places (array of instances)
    attr_reader :places, :transitions

    # Without parameters, it behaves as #places. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of places, and which
    # are then presented as hash { place_instance => object }.
    def places_ *aa, &b
      aa.empty? && b.nil? ? places : Hash[ places.zip( send *aa, &b ) ]
    end
    
    # Exposing @transitions (array of instances)
    attr_reader :transitions

    # Without parameters, it behaves as #transitions. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of transitions, and
    # which are then presented as hash { transition_instance => object }.
    def transitions_ *aa, &b
      aa.empty? && b.nil? ? transitions : Hash[ transitions.zip( send *aa, &b ) ]
    end

    # Array of place names.
    def pp; places.map &:name end

    # Without parameters, it behaves as #pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of places, and which
    # are then presented as hash { place_name => object }. Place instances
    # are used as hash keys for nameless places.
    def pp_ *aa, &b
      if aa.empty? and b.nil? then pp else
        Hash[ places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Array of place names as symbols.
    def pp_sym; pp.map { |o| o.to_sym rescue nil } end
    alias :ppß :pp_sym

    # Without parameters, it behaves as #pp_sym. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of places, and which
    # are then presented as hash { place_name_symbol => object }. Place
    # instances are used as keys for nameless places.
    def pp_sym_ *aa, &b
      if aa.empty? and b.nil? then pp_sym else
        Hash[ places.map { |p| p.name.to_sym rescue p }
                .zip( send *aa, &b ) ]
      end
    end
    alias :ppß_ :pp_sym_

    # Array of transition names.
    def tt; transitions.map &:name end

    # Without parameters, it behaves as #tt. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of transitions, and
    # which are then presented as hash { transition_name => object }.
    # Transition instances are used as hash keys for nameless transitions.
    def tt_ *aa, &b
      if aa.empty? and b.nil? then tt else
        Hash[ transitions.map { |t| t.name.nil? ? t : t.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Array of transition names as symbols.
    def tt_sym; tt.map { |o| o.to_sym rescue nil } end
    alias :ttß :tt_sym

    # Without parameters, it behaves as #tt_sym. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of transitions, and
    # which are then returned as hash { transition_name_symbol => object }.
    # Transition instances are used as hash keys for nameless transitions.
    def tt_sym_ *aa, &b
      if aa.empty? and b.nil? then tt_sym else
        Hash[ transitions.map { |t| t.name.to_sym rescue t } 
                .zip( send *aa, &b ) ]
      end
    end
    alias :ttß_ :tt_sym_

    # Exposing @place_clamps (hash with place instances as keys)
    attr_reader :place_clamps

    # Exposing @p_clamps (hash with place name symbols as keys)
    def p_clamps
      place_clamps.with_keys { |k| k.name.nil? ? k : k.name.to_sym }
    end

    # Free places (array of instances)
    def free_places; places.select { |p| @initial_marking.keys.include? p } end

    # Without parameters, it behaves as #free_places. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of free places, and which
    # are then presented as hash { place_instance => object }.
    def free_places_ *aa, &b
      aa.empty? && b.nil? ? free_places :
        Hash[ free_places.zip( send *aa, &b ) ]
    end

    # Clamped places (array of instances)
    def clamped_places; places.select { |p| @place_clamps.keys.include? p } end

    # Without parameters, it behaves as #clamped_places. If parameters are
    # given, these are treated as a message to be sent to self (as #send
    # method parameters), with the return value expected to be a collection
    # of objects, whose number is the same as the number of clamped places,
    # and which are then presented as hash { place_instance => object }.
    def clamped_places_ *aa, &b
       aa.empty? && b.nil? ? clamped_places :
        Hash[ clamped_places.zip( send *aa, &b ) ]
    end

    # Free places (array of instance names)
    def free_pp; free_places.map &:name end

    # Without parameters, it behaves as #free_pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of free places, and which
    # are then presented as hash { place_instance_name => object }. Place
    # instances are used as keys for nameless places.
    def free_pp_ *aa, &b
      if aa.empty? and b.nil? then free_pp else
        Hash[ free_places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Free places (array of instance names as symbols)
    def free_pp_sym; free_pp.map { |o| o.to_sym rescue nil } end
    alias :free_ppß :free_pp_sym

    # Without parameters, it behaves as #free_pp_sym. If parameters are
    # given, these are treated as a message to be sent to self (as #send
    # method parameters), with the return value expected to be a collection
    # of objects, whose number is the same as the number of free places,
    # and which are then returned as hash { free_place_name_symbol => object }.
    # Place instances are used as keys for nameless places
    def free_pp_sym_ *aa, &b
      if aa.empty? and b.nil? then free_pp_sym else
        Hash[ free_places.map { |p| p.name.to_sym rescue p }
                .zip( send *aa, &b ) ]
      end
    end
    alias :free_ppß_ :free_pp_sym_

    # Clamped places (array of instance names)
    def clamped_pp *aa; clamped_places.map &:name end

    # Without parameters, it behaves as #clamped_pp. If parameters are given,
    # these are treated as a message to be sent to self (as #send method
    # parameters), with the return value expected to be a collection of
    # objects, whose number is the same as the number of clamped places, and
    # which are then presented as hash { place_instance_name => object }. Place
    # instances are used as keys for nameless places.
    def clamped_pp_ *aa, &b
      if aa.empty? and b.nil? then clamped_pp else
        Hash[ clamped_places.map { |p| p.name.nil? ? p : p.name }
                .zip( send *aa, &b ) ]
      end
    end

    # Clamped places (array of instance names as symbols)
    def clamped_pp_sym *aa; clamped_pp.map { |o| o.to_sym rescue nil } end
    alias :clamped_ppß :clamped_pp_sym

    # Without parameters, it behaves as #clamped_pp_sym. If parameters are
    # given, these are treated as a message to be sent to self (as #send
    # method parameters), with the return value expected to be a collection
    # of objects, whose number is the same as the number of clamped places,
    # and which are then returned as hash { clamped_place_name_symbol =>
    # object }. Place instances are used as keys for nameless places
    def clamped_pp_sym_ *aa, &b
      if aa.empty? and b.nil? then clamped_pp_sym else
        Hash[ clamped_places.map { |p| p.name.to_sym rescue p }
                .zip( send *aa, &b ) ]
      end
    end
    alias :clamped_ppß_ :clamped_pp_sym_









    # Marking of free places as a column vector
    def marking_vector
      free_places_to_all_places_matrix.t * @marking_vector
    end
    alias :𝖒 :marking_vector
    alias :marking_vector_of_free_places :marking_vector
    alias :𝖒_free :marking_vector

    # Marking of clamped places as an array
    def marking_array_of_clamped_places
      marking_vector_of_clamped_places.column( 0 ).to_a
    end

    # Marking of clamped places as a hash with place instances as keys
    def marking_of_clamped_places
      Hash[ clamped_places.zip( marking_array_of_clamped_places ) ]
    end

    # Marking of clamped places as a hash with place names as keys
    def m_clamped
      Hash[ clamped_pp.map{|e| e.to_sym rescue nil }
              .zip( marking_array_of_clamped_places ) ]
    end

    # Marking of clamped places as a column vector
    def marking_vector_of_clamped_places
      clamped_places_to_all_places_matrix.t * @marking_vector
    end
    alias :𝖒_clamped :marking_vector_of_clamped_places

    # Marking array for all places
    def marking_array_of_all_places; marking_vector!.column( 0 ).to_a end
    alias :marking_array! :marking_array_of_all_places

    # Marking of all places as a hash with place instances as keys
    def marking_of_all_places; Hash[ places.zip( marking_array! ) ] end
    alias :marking! :marking_of_all_places

    # Marking of all places as a hash with place names as keys
    def m_all; Hash[ pp.map{|e| e.to_sym rescue nil }
                       .zip( marking_array! ) ]
    end
    alias :m! :m_all

    # Marking of all places as a column vector
    def marking_vector_of_all_places; @marking_vector end
    alias :marking_vector! :marking_vector_of_all_places
    alias :𝖒_all :marking_vector_of_all_places
    alias :𝖒! :marking_vector_of_all_places

    # Creation of stoichiometry matrix for an arbitrary array of stoichio.
    # transitions, that maps (has the number of rows equal to) the free places.
    def create_stoichiometry_matrix_for( array_of_S_transitions )
      array_of_S_transitions.map { |t| sparse_stoichiometry_vector( t ) }
        .reduce( Matrix.empty( free_places.size, 0 ), :join_right )
    end
    alias :create_𝕾_for :create_stoichiometry_matrix_for
    alias :stoichiometry_matrix_for :create_stoichiometry_matrix_for
    alias :𝕾_for :create_stoichiometry_matrix_for

    # Creation of stoichiometry matrix for an arbitrary array of stoichio.
    # transitions, that maps (has the number of rows equal to) all the places.
    def create_stoichiometry_matrix_for! array_of_S_transitions
      array_of_S_transitions.map { |t| sparse_stoichiometry_vector! t }
        .reduce( Matrix.empty( places.size, 0 ), :join_right )
    end
    alias :create_𝕾_for! :create_stoichiometry_matrix_for!
    alias :stoichiometry_matrix_for! :create_stoichiometry_matrix_for!
    alias :𝕾_for! :create_stoichiometry_matrix_for!

    # 3. Stoichiometry matrix for timeless stoichiometric transitions
    attr_reader :stoichiometry_matrix_for_timeless_stoichiometric_transitions
    alias :stoichiometry_matrix_for_tS_transitions \
          :stoichiometry_matrix_for_timeless_stoichiometric_transitions
    alias :𝕾_for_tS_transitions \
          :stoichiometry_matrix_for_timeless_stoichiometric_transitions

    # 4. Stoichiometry matrix for timed rateless stoichiometric transitions
    attr_reader :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions
    alias :stoichiometry_matrix_for_TSr_transitions \
          :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions
    alias :𝕾_for_TSr_transitions \
          :stoichiometry_matrix_for_timed_rateless_stoichiometric_transitions

    # 6. Stoichiometry matrix for stoichiometric transitions with rate
    attr_reader :stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    alias :stoichiometry_matrix_for_SR_transitions \
          :stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    alias :𝕾_for_SR_transitions \
          :stoichiometry_matrix_for_stoichiometric_transitions_with_rate

    # Stoichiometry matrix for stoichiometric transitions with rate.
    # By calling this method, the caller asserts that there are only
    # stoichiometric transitions with rate in the simulation (or error).
    def stoichiometry_matrix!
      txt = "The simulation contains also non-stoichiometric transitions. " +
            "Use method #stoichiometry_matrix_for_stoichiometric_transitions."
      raise txt unless s_transitions.empty? && r_transitions.empty?
      return stoichiometry_matrix_for_stoichiometric_transitions_with_rate
    end
    alias :𝕾! :stoichiometry_matrix!

    # ----------------------------------------------------------------------
    # Exposing the collection of 1. ts transitions

    # Array of ts transitions
    def timeless_nonstoichiometric_transitions
      from_net = net.timeless_nonstoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :ts_transitions :timeless_nonstoichiometric_transitions

    # Hash mapper for #ts_transitions (see #transitions_ method description)
    def timeless_nonstoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then ts_transitions else
        Hash[ ts_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :ts_transitions_ :timeless_nonstoichiometric_transitions_

    # Array of ts transition names
    def timeless_nonstoichiometric_tt
      timeless_nonstoichiometric_transitions.map &:name
    end
    alias :ts_tt :timeless_nonstoichiometric_tt

    # Hash mapper for #ts_tt (see #tt_ method description)
    def timeless_nonstoichiometric_tt_ *aa, &b
      if aa.empty? && b.nil? then ts_tt else
        Hash[ ts_transitions
                .map { |t| t.name.nil? ? t : t.name }
                .zip( send *aa, &b ) ]
      end
    end
    alias :ts_tt_ :timeless_nonstoichiometric_tt_

    # Array of ts transition names as symbols
    def timeless_nonstoichiometric_tt_sym
      timeless_nonstoichiometric_tt.map { |t| t.to_sym rescue nil }
    end
    alias :timeless_nonstoichiometric_ttß :timeless_nonstoichiometric_tt_sym
    alias :ts_tt_sym :timeless_nonstoichiometric_tt
    alias :ts_ttß :ts_tt_sym

    # Hash mapper for #ts_tt_sym (see #tt_sym_ method description)
    def timeless_nonstoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then ts_tt_sym else
        Hash[ ts_transitions
              .map { |t| t.name.to_sym rescue t }
              .zip( send *aa, &b ) ]
      end
    end
    alias :timeless_nonstoichiometric_ttß_ :timeless_nonstoichiometric_tt_sym_
    alias :ts_tt_sym_ :timeless_nonstoichiometric_tt_sym_
    alias :ts_ttß_ :ts_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of 2. tS transitions

    # Array of tS transitions
    def timeless_stoichiometric_transitions
      from_net = net.timeless_stoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :tS_transitions :timeless_stoichiometric_transitions

    # Hash mapper for #tS_transitions (see #transitions_ method description)
    def timeless_stoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then tS_transitions else
        Hash[ tS_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :tS_transitions_ :timeless_nonstoichiometric_transitions_

    # Array of tS transition names
    def timeless_stoichiometric_tt
      timeless_stoichiometric_transitions.map &:name
    end
    alias :tS_tt :timeless_stoichiometric_tt

    # Hash mapper for #tS_tt (see #tt_ method description)
    def timeless_stoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? tS_tt : Hash[ tS_tt.zip( send *aa, &b ) ]
    end
    alias :tS_tt_ :timeless_stoichiometric_tt_

    # Array of tS transition name symbols
    def timeless_stoichiometric_tt_sym
      timeless_stoichiometric_tt.map { |n| n.to_sym rescue nil }
    end
    alias :timeless_stoichiometric_ttß :timeless_stoichiometric_tt_sym
    alias :tS_tt_sym :timeless_stoichiometric_tt_sym
    alias :tS_ttß :timeless_stoichiometric_ttß

    # Hash mapper for #tS_tt_sym (see #tt_sym_ method description)
    def timeless_stoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then tS_tt_sym else
        Hash[ tS_transitions
                .map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :timeless_stoichiometric_ttß_ :timeless_stoichiometric_tt_sym_
    alias :tS_tt_sym_ :timeless_stoichiometric_tt_sym_
    alias :tS_ttß :timeless_stoichiometric_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of 3. Tsr transitions

    # Array of Tsr transitions
    def timed_nonstoichiometric_transitions_without_rate
      from_net = net.timed_rateless_nonstoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :timed_rateless_nonstoichiometric_transitions \
          :timed_nonstoichiometric_transitions_without_rate
    alias :Tsr_transitions :timed_nonstoichiometric_transitions_without_rate

    # Hash mapper for #Tsr_transitions (see #transitions_ method description)
    def timed_nonstoichiometric_transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then self.Tsr_transitions else
        Hash[ self.Tsr_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_nonstoichiometric_transitions_ \
          :timed_nonstoichiometric_transitions_without_rate_
    alias :Tsr_transitions_ \
          :timed_nonstoichiometric_transitions_without_rate_

    # Array of Tsr transition names
    def timed_nonstoichiometric_tt_without_rate
      timed_nonstoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_nonstoichiometric_tt \
          :timed_nonstoichiometric_tt_without_rate
    alias :Tsr_tt :timed_nonstoichiometric_tt_without_rate

    # Hash mapper for #Tsr_tt (see #tt_ method description)
    def timed_nonstoichiometric_tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? self.Tsr_transitions :
        Hash[ self.Tsr_transitions.zip( send *aa, &b ) ]
    end
    alias :timed_rateless_nonstoichiometric_tt_ \
          :timed_nonstoichiometric_transitions_without_rate_
    alias :Tsr_tt_ :timed_nonstoichiometric_tt_without_rate_

    # Array of Tsr transition names as symbols
    def timed_rateless_nonstoichiometric_tt_sym
      timed_rateless_nonstoichiometric_tt.map { |n| n.to_sym rescue n }
    end
    alias :timed_rateless_nonstoichiometric_ttß \
          :timed_rateless_nonstoichiometric_tt_sym
    alias :Tsr_tt_sym :timed_rateless_nonstoichiometric_tt_sym
    alias :Tsr_ttß :timed_rateless_nonstoichiometric_tt_sym

    # Hash mapper for #Tsr_tt_sym (see #tt_sym_ method description)
    def timed_rateless_nonstoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.Tsr_tt_sym else
        Hash[ self.Tsr_transitions
                .map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_nonstoichiometric_ttß_ \
          :timed_rateless_nonstoichiometric_tt_sym_
    alias :Tsr_tt_sym_ :timed_rateless_nonstoichiometric_tt_sym_
    alias :Tsr_ttß_ :timed_rateless_nonstoichiometric_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of 4. TSr transitions

    # Array of TSr transitions
    def timed_stoichiometric_transitions_without_rate
      from_net = net.timed_rateless_stoichiometric_transitions
      @transitions.select{ |t| from_net.include? t }
    end
    alias :timed_rateless_stoichiometric_transitions \
          :timed_stoichiometric_transitions_without_rate
    alias :TSr_transitions :timed_stoichiometric_transitions_without_rate

    # Hash mapper for #TSr_transitions (see #transitions_ method description)
    def timed_stoichiometric_transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then self.TSr_transitions else
        Hash[ self.TSr_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_stoichiometric_transitions_ \
          :timed_stoichiometric_transitions_without_rate_
    alias :TSr_transitions_ \
          :timed_stoichiometric_transitions_without_rate_

    # Array of TSr transition names
    def timed_stoichiometric_tt_without_rate
      timed_stoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_stoichiometric_tt \
          :timed_stoichiometric_tt_without_rate
    alias :TSr_tt :timed_stoichiometric_tt_without_rate

    # Hash mapper for #TSr_tt (see #tt_ method description)
    def timed_stoichiometric_tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? self.TSr_tt :
        Hash[ self.TSr_tt.zip( send *aa, &b ) ]
    end
    alias :timed_rateless_stoichiometric_tt_ \
          :timed_stoichiometric_transitions_without_rate_
    alias :TSr_tt_ :timed_stoichiometric_tt_without_rate_

    # Array of TSr transition names as symbols
    def timed_rateless_stoichiometric_tt_sym
      timed_rateless_stoichiometric_tt.map { |n| n.to_sym rescue n }
    end
    alias :timed_rateless_stoichiometric_ttß \
          :timed_rateless_stoichiometric_tt_sym
    alias :TSr_tt_sym :timed_rateless_stoichiometric_tt_sym
    alias :TSr_ttß :timed_rateless_stoichiometric_tt_sym

    # Hash mapper for #Tsr_tt_sym (see #tt_sym_ method description)
    def timed_rateless_stoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.TSr_tt_sym else
        Hash[ self.TSr_transitions
                .map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :timed_rateless_stoichiometric_ttß_ \
          :timed_rateless_stoichiometric_tt_sym_
    alias :TSr_tt_sym_ :timed_rateless_stoichiometric_tt_sym_
    alias :TSr_ttß_ :timed_rateless_stoichiometric_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of 5. sR transitions

    # Array of sR transitions
    def nonstoichiometric_transitions_with_rate
      from_net = net.nonstoichiometric_transitions_with_rate
      @transitions.select { |t| from_net.include? t }
    end
    alias :sR_transitions :nonstoichiometric_transitions_with_rate

    # Hash mapper for #sR_transitions (see #transitions_ method description)
    def nonstoichiometric_transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then sR_transitions else
        Hash[ sR_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :sR_transitions_ :nonstoichiometric_transitions_with_rate_

    # Array of sR transition names
    def nonstoichiometric_tt_with_rate
      nonstoichiometric_transitions_with_rate.map &:name
    end
    alias :sR_tt :nonstoichiometric_tt_with_rate

    # Hash mapper for #sR_tt (see #tt_ method description)
    def nonstoichiometric_tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? sR_tt : Hash[ sR_tt.zip( send *aa, &b ) ]
    end
    alias :sR_tt_ :nonstoichiometric_tt_with_rate_

    # Array of sR transition names as symbols
    def sR_tt_sym
      nonstoichiometric_tt_with_rate.map { |n| n.to_sym rescue n }
    end
    alias :sR_ttß :sR_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def sR_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then sR_tt_sym else
        Hash[ sR_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :sR_ttß_ :sR_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of 6. SR transitions

    # Array of SR transitions
    def stoichiometric_transitions_with_rate
      from_net = net.stoichiometric_transitions_with_rate
      @transitions.select { |t| from_net.include? t }
    end
    alias :SR_transitions :stoichiometric_transitions_with_rate

    # Hash mapper for #SR_transitions (see #transitions_ method description)
    def stoichiometric_transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then self.SR_transitions else
        Hash[ self.SR_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :SR_transitions_ :stoichiometric_transitions_with_rate_

    # Array of SR transition names
    def stoichiometric_tt_with_rate
      stoichiometric_transitions_with_rate.map &:name
    end
    alias :SR_tt :stoichiometric_tt_with_rate

    # Hash mapper for #sR_tt (see #tt_ method description)
    def stoichiometric_tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? self.SR_tt :
        Hash[ self.SR_tt.zip( send *aa, &b ) ]
    end
    alias :SR_tt_ :stoichiometric_tt_with_rate_

    # Array of sR transition names as symbols
    def SR_tt_sym
      stoichiometric_tt_with_rate.map { |n| n.to_sym rescue n }
    end
    alias :SR_ttß :SR_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def SR_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.SR_tt_sym else
        Hash[ self.SR_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :SR_ttß_ :SR_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of transitions with explicit assignment action
    # (A transitions)

    # Array of transitions with explicit assignment action
    def transitions_with_explicit_assignment_action
      from_net = net.transitions_with_explicit_assignment_action
      @transitions.select { |t| from_net.include? t }
    end
    alias :assignment_transitions :transitions_with_explicit_assignment_action
    alias :A_transitions :transitions_with_explicit_assignment_action

    # Hash mapper for #A_transitions (see #transitions_ method description)
    def transitions_with_explicit_assignment_action_ *aa, &b
      if aa.empty? && b.nil? then self.A_transitions else
        Hash[ self.A_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :A_transitions_ :transitions_with_explicit_assignment_action_
    alias :assignment_transitions_ :A_transitions_

    # Array of names of transitions with explicit assignment action
    def tt_with_explicit_assignment_action
      transitions_with_explicit_assignment_action.map &:name
    end
    alias :assignment_tt :tt_with_explicit_assignment_action
    alias :A_tt :tt_with_explicit_assignment_action

    # Hash mapper for #A_tt (see #tt_ method description)
    def tt_with_explicit_assignment_action_ *aa, &b
      aa.empty? && b.nil? ? self.A_tt :
        Hash[ self.A_tt.zip( send *aa, &b ) ]
    end
    alias :assignment_tt_ :tt_with_explicit_assignment_action_
    alias :A_tt_ :tt_with_explicit_assignment_action_

    # Array of A transition names as symbols
    def assignment_tt_sym
      assignment_tt.map { |n| n.to_sym rescue n }
    end
    alias :assignment_ttß :assignment_tt_sym
    alias :A_tt_sym :assignment_tt_sym
    alias :A_ttß :assignment_tt_sym

    # Hash mapper for #A_tt (see #tt_sym_ method description)
    def assignment_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.A_tt_sym else
        Hash[ self.A_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :assignment_ttß_ :assignment_tt_sym_
    alias :A_tt_sym_ :assignment_tt_sym_
    alias :A_ttß_ :assignment_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of stoichiometric transitions of any kind
    # (S transitions)

    # Array of stoichiometric transitions (of any kind)
    def stoichiometric_transitions
      stoichio_from_net = net.stoichiometric_transitions
      @transitions.select{ |t| stoichio_from_net.include?( t ) }
    end
    alias :S_transitions :stoichiometric_transitions

    # Hash mapper for #S_transitions (see #transitions_ method description)
    def stoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then self.S_transitions else
        Hash[ self.S_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :S_transitions_ :stoichiometric_transitions_

    # Array of names of stoichiometric transitions (of any kind)
    def stoichiometric_tt; stoichiometric_transitions.map &:name end
    alias :S_tt :stoichiometric_tt

    # Hash mapper for #A_tt (see #tt_ method description)
    def stoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? self.S_tt : Hash[ self.S_tt.zip( send *aa, &b ) ]
    end
    alias :S_tt_ :stoichiometric_tt_

    # Array of S transition names as symbols
    def stoichiometric_tt_sym
      stoichiometric_tt_with_rate.map { |n| n.to_sym rescue n }
    end
    alias :stoichiometric_ttß :stoichiometric_tt_sym
    alias :S_tt_sym :stoichiometric_tt_sym
    alias :S_ttß :stoichiometric_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def stoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.S_tt_sym else
        Hash[ self.S_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :stoichiometric_ttß_ :stoichiometric_tt_sym_
    alias :S_tt_sym_ :stoichiometric_tt_sym_
    alias :S_ttß_ :stoichiometric_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of nonstoichiometric transitions of any kind
    # (s transitions)

    # Array of nonstoichiometric transitions (of any kind)
    def nonstoichiometric_transitions
      non_stoichio_from_net = net.nonstoichiometric_transitions
      @transitions.select{ |t| non_stoichio_from_net.include?( t ) }
    end
    alias :s_transitions :nonstoichiometric_transitions

    # Hash mapper for #s_transitions (see #transitions_ method description)
    def nonstoichiometric_transitions_ *aa, &b
      if aa.empty? && b.nil? then s_transitions else
        Hash[ s_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :s_transitions_ :nonstoichiometric_transitions_

    # Array of names of nonstoichiometric transitions (of any kind)
    def nonstoichiometric_tt; nonstoichiometric_transitions.map &:name end
    alias :s_tt :nonstoichiometric_tt

    # Hash mapper for #s_tt (see #tt_ method description)
    def nonstoichiometric_tt_ *aa, &b
      aa.empty? && b.nil? ? s_tt : Hash[ self.s_tt.zip( send *aa, &b ) ]
    end
    alias :s_tt_ :nonstoichiometric_tt_

    # Array of sR transition names as symbols
    def nonstoichiometric_tt_sym
      nonstoichiometric_tt.map { |n| n.to_sym rescue n }
    end
    alias :nonstoichiometric_ttß :nonstoichiometric_tt_sym
    alias :s_tt_sym :nonstoichiometric_tt_sym
    alias :s_ttß :nonstoichiometric_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def nonstoichiometric_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then s_tt_sym else
        Hash[ s_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :nonstoichiometric_ttß_ :nonstoichiometric_tt_sym_
    alias :s_tt_sym_ :nonstoichiometric_tt_sym_
    alias :s_ttß_ :nonstoichiometric_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of transitions with rate (R transitions),
    # otherwise of any kind

    # Array of transitions with rate (of any kind)
    def transitions_with_rate
      from_net = net.transitions_with_rate
      @transitions.select{ |t| from_net.include?( t ) }
    end
    alias :R_transitions :transitions_with_rate

    # Hash mapper for #R_transitions (see #transitions_ method description)
    def transitions_with_rate_ *aa, &b
      if aa.empty? && b.nil? then self.R_transitions else
        Hash[ self.R_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :R_transitions_ :transitions_with_rate_

    # Array of names of transitions with rate (of any kind)
    def tt_with_rate; transitions_with_rate.map &:name end
    alias :R_tt :tt_with_rate

    # Hash mapper for #R_tt (see #tt_ method description)
    def tt_with_rate_ *aa, &b
      aa.empty? && b.nil? ? self.R_tt : Hash[ self.R_tt.zip( send *aa, &b ) ]
    end
    alias :R_tt_ :tt_with_rate_

    # Array of sR transition names as symbols
    def R_tt_sym
      self.R_tt.map { |n| n.to_sym rescue n }
    end
    alias :R_ttß :R_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def R_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then self.R_tt_sym else
        Hash[ self.R_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :R_ttß_ :R_tt_sym_

    # ----------------------------------------------------------------------
    # Exposing the collection of rateless transitions (r transitions),
    # otherwise of any kind

    # Array of rateless transitions (of any kind)
    def transitions_without_rate
      from_net = net.transitions_without_rate
      @transitions.select{ |t| from_net.include?( t ) }
    end
    alias :rateless_transitions :transitions_without_rate
    alias :r_transitions :transitions_without_rate

    # Hash mapper for #r_transitions (see #transitions_ method description)
    def transitions_without_rate_ *aa, &b
      if aa.empty? && b.nil? then r_transitions else
        Hash[ r_transitions.zip( send *aa, &b ) ]
      end
    end
    alias :rateless_transitions_ :transitions_without_rate_
    alias :r_transitions_ :transitions_without_rate_

    # Array of names of rateless transitions (of any kind)
    def tt_without_rate; transitions_without_rate.map &:name end
    alias :rateless_tt :tt_without_rate
    alias :r_tt :tt_without_rate

    # Hash mapper for #r_tt (see #tt_ method description)
    def tt_without_rate_ *aa, &b
      aa.empty? && b.nil? ? r_tt : Hash[ r_tt.zip( send *aa, &b ) ]
    end
    alias :rateless_tt_ :tt_without_rate_
    alias :r_tt_ :tt_without_rate_

    # Array of sR transition names as symbols
    def r_tt_sym
      tt_without_rate.map { |n| n.to_sym rescue n }
    end
    alias :r_ttß :r_tt_sym

    # Hash mapper for #sR_tt_sym (see #tt_sym_ method description)
    def r_tt_sym_ *aa, &b
      if aa.empty? && b.nil? then r_tt_sym else
        Hash[ r_transitions.map { |t| t.name.to_sym rescue t }
                .zip( send *aa, &b ) ]
      end
    end
    alias :r_ttß_ :r_tt_sym_

    # ----------------------------------------------------------------------
    # Methods presenting other simulation assets

    # ----------------------------------------------------------------------
    # 1. Timeless nonstoichiometric transitions (ts_transitions)

    # Exposing Δ state closures for ts transitions
    attr_reader :delta_state_closures_for_timeless_nonstoichiometric_transitions
    alias :Δ_closures_for_ts_transitions \
          :delta_state_closures_for_timeless_nonstoichiometric_transitions

    # Δ state contribution if these ts transitions fire once. The closures
    # are called in their order, but the state update is not performed
    # between the calls (ie. they fire "simultaneously").
    def delta_state_if_timeless_nonstoichiometric_transitions_fire_once
      Δ_closures_for_ts_transitions.map( &:call )
        .reduce( @zero_column_vector_sized_as_free_places, :+ )
    end
    alias :Δ_if_timeless_nonstoichiometric_transitions_fire_once \
          :delta_state_if_timeless_nonstoichiometric_transitions_fire_once
    alias :Δ_if_ts_transitions_fire_once \
          :Δ_if_timeless_nonstoichiometric_transitions_fire_once

    # ----------------------------------------------------------------------
    # 2. Timed rateless nonstoichiometric transitions (Tsr_transitions)
    # Their closures do take Δt as argument, but do not expose their ∂
    # (or they might not even have one)

    # Exposing Δ state closures for Tsr transitions
    attr_reader :delta_state_closures_for_timed_rateless_nonstoichiometric_transitions
    alias :Δ_closures_for_Tsr_transitions \
          :delta_state_closures_for_timed_rateless_nonstoichiometric_transitions

    # Δ state contribution for Tsr transitions given Δt
    def delta_state_for_timed_rateless_nonstoichiometric_transitions( Δt )
      Δ_closures_for_Tsr_transitions.map { |cl| cl.( Δt ) }
        .reduce( @zero_column_vector_sized_as_free_places, :+ )
    end
    alias :Δ_for_timed_rateless_nonstoichiometric_transitions \
          :delta_state_for_timed_rateless_nonstoichiometric_transitions
    alias :Δ_for_Tsr_transitions \
          :delta_state_for_timed_rateless_nonstoichiometric_transitions

    # ----------------------------------------------------------------------
    # 3. Timeless stoichiometric transitions (tS_transitions)
    # These transitions are timeless, but stoichiometric. It means that
    # their closures do not output Δ state contribution directly, but instead
    # they output a single number, which is a transition action, and Δ state
    # is then computed from it by muliplying the the action vector with the
    # stoichiometric matrix.

    # Exposing action closures for tS transitions
    attr_reader :action_closures_for_timeless_stoichiometric_transitions
    alias :action_closures_for_tS_transitions \
          :action_closures_for_timeless_stoichiometric_transitions

    # Action vector for if tS transitions fire once. The closures are called
    # in their order, but the state update is not performed between the
    # calls (ie. they fire "simultaneously").
    def action_vector_for_timeless_stoichiometric_transitions
      Matrix.column_vector action_closures_for_tS_transitions.map( &:call )
    end
    alias :action_vector_for_tS_transitions \
          :action_vector_for_timeless_stoichiometric_transitions
    alias :𝖆_for_tS_transitions \
          :action_vector_for_timeless_stoichiometric_transitions

    # Action vector if tS transitions fire once, like the previous method.
    # But by calling this method, the caller asserts that all timeless
    # transitions in this simulation are stoichiometric (or error is raised).
    def action_vector_for_timeless_transitions!
      txt = "The simulation also contains nonstoichiometric timeless " +
        "transitions. Consider using " +
        "#action_vector_for_timeless_stoichiometric_transitions."
      raise txt unless timeless_nonstoichiometric_transitions.empty?
      action_vector_for_timeless_stoichiometric_transitions
    end
    alias :action_vector_for_t_transitions! \
          :action_vector_for_timeless_transitions!
    alias :𝖆_for_t_transitions! :action_vector_for_timeless_transitions!

    # Δ state contribution for tS transitions 
    def delta_state_if_timeless_stoichiometric_transitions_fire_once
      𝕾_for_tS_transitions * action_vector_for_tS_transitions
    end
    alias :Δ_if_timeless_stoichiometric_transitions_fire_once \
          :delta_state_if_timeless_stoichiometric_transitions_fire_once
    alias :Δ_if_tS_transitions_fire_once \
          :Δ_if_timeless_stoichiometric_transitions_fire_once

    # ----------------------------------------------------------------------
    # 4. Timed rateless stoichiometric transitions (TSr_transitions)
    # Same as Tsr transitions, but stoichiometric - their closures do not
    # return Δ contribution, but transition action, that has to be
    # multiplied with the stoichiometry vector tor obtain Δ contribution.

    # Exposing action closures for TSr transitions.
    attr_reader :action_closures_for_timed_rateless_stoichiometric_transitions
    alias :action_closures_for_TSr_transitions \
          :action_closures_for_timed_rateless_stoichiometric_transitions

    # By calling this method, the caller asserts that all timeless transitions
    # in this simulation are stoichiometric (or error is raised).
    def action_closures_for_timed_rateless_transitions!
      txt = "The simulation also contains nonstoichiometric timed rateless " +
        "transitions. Consider using " +
        "#action_closures_for_timed_rateless_stoichiometric_transitions."
      raise txt unless timed_rateless_stoichiometric_transitions.empty?
      action_closures_for_timed_rateless_stoichiometric_transitions
    end
    alias :action_closures_for_Tr_transitions! \
          :action_closures_for_timed_rateless_transitions!

    # Action vector for timed rateless stoichiometric transitions
    def action_vector_for_timed_rateless_stoichiometric_transitions( Δt )
      Matrix.column_vector action_closures_for_TSr_transitions
        .map { |cl| cl.( Δt ) }
    end
    alias :action_vector_for_TSr_transitions \
          :action_vector_for_timed_rateless_stoichiometric_transitions
    alias :𝖆_for_TSr_transitions \
          :action_vector_for_timed_rateless_stoichiometric_transitions

    # Action vector for timed rateless stoichiometric transitions
    # By calling this method, the caller asserts that all timeless transitions
    # in this simulation are stoichiometric (or error is raised).
    def action_vector_for_timed_rateless_transitions!( Δt )
      txt = "The simulation also contains nonstoichiometric timed rateless " +
        "transitions. Consider using " +
        "#action_vector_for_timed_rateless_stoichiometric_transitions."
      raise txt unless timed_rateless_stoichiometric_transitions.empty?
      action_vector_for_timed_rateless_stoichiometric_transitions( Δt )
    end
    alias :action_vector_for_Tr_transitions! \
          :action_vector_for_timed_rateless_transitions!
    alias :𝖆_for_Tr_transitions! :action_vector_for_Tr_transitions!

    # Computes Δ state for TSr transitions, given a Δt
    def delta_state_for_timed_rateless_stoichiometric_transitions( Δt )
      𝕾_for_TSr_transitions * action_vector_for_TSr_transitions( Δt )
    end
    alias :Δ_for_timed_rateless_stoichiometric_transitions \
          :delta_state_for_timed_rateless_stoichiometric_transitions
    alias :Δ_for_TSr_transitions \
          :delta_state_for_timed_rateless_stoichiometric_transitions

    # ----------------------------------------------------------------------
    # 5. Nonstoichiometric transitions with rate (sR_transitions)
    # Whether nonstoichiometric, or stoichiometric, transitions with rate
    # explicitly provide their contribution to the the state differential,
    # rather than just contribution to the Δ state.

    # Exposing rate closures for sR transitions.
    attr_reader :rate_closures_for_nonstoichiometric_transitions_with_rate
    alias :rate_closures_for_sR_transitions \
          :rate_closures_for_nonstoichiometric_transitions_with_rate

    # Rate closures for sR transitions.
    # By calling this method, the caller asserts that there are no rateless
    # transitions in the simulation (or error is raised).
    def rate_closures_for_nonstoichiometric_transitions!
      raise "The simulation also contains rateless transitions. " +
        "Consider using " +
        "#rate_closures_for_stoichiometric_transitions_with_rate" unless
        rateless_transitions.empty?
      rate_closures_for_sR_transitions
    end
    alias :rate_closures_for_s_transitions! \
          :rate_closures_for_nonstoichiometric_transitions!

    # State differential for sR transitions
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

    # ----------------------------------------------------------------------
    # 6. Stoichiometric transitions with rate (SR_transitions)
    # Whether nonstoichiometric, or stoichiometric, transitions with rate
    # explicitly provide their contribution to the the state differential,
    # rather than just contribution to the Δ state.

    # Exposing rate closures for SR transitions
    attr_reader :rate_closures_for_stoichiometric_transitions_with_rate
    alias :rate_closures_for_SR_transitions \
          :rate_closures_for_stoichiometric_transitions_with_rate

    # Rate closures for SR transitions.
    # By calling this method, the caller asserts that there are no rateless
    # transitions in the simulation (or error is raised).
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
    def flux_vector_for_stoichiometric_transitions_with_rate
      Matrix.column_vector( rate_closures_for_SR_transitions.map( &:call ) )
    end
    alias :flux_vector_for_SR_transitions \
          :flux_vector_for_stoichiometric_transitions_with_rate
    alias :𝖋_for_stoichiometric_transitions_with_rate \
          :flux_vector_for_stoichiometric_transitions_with_rate
    alias :𝖋_for_SR_transitions \
          :flux_vector_for_stoichiometric_transitions_with_rate

    # Flux vector for SR transitions. Same as the previous method, but
    # the caller asserts that there are only stoichiometric transitions
    # with rate in the simulation (or error).
    def flux_vector!
      raise "The simulation must contain only stoichiometric transitions " +
        "with rate!" unless s_transitions.empty? && r_transitions.empty?
      flux_vector_for_stoichiometric_transitions_with_rate
    end
    alias :𝖋! :flux_vector!

    # Flux of SR transitions as hash with transition name symbols as keys.
    def flux_for_SR_tt_sym; self.SR_ttß_ :flux_vector_for_SR_transitions end
    alias :flux_for_SR_ttß :flux_for_SR_tt_sym

    # Same as #flux_for_SR_tt_sym, but with caller asserting that there are
    # none but SR transitions in the simulation (or error).
    def f!; self.SR_ttß_ :flux_vector! end

    # State differential for SR transitions
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
    def Euler_action_vector_for_stoichiometric_transitions_with_rate( Δt )
      flux_vector_for_SR_transitions * Δt
    end
    alias :euler_action_vector_for_stoichiometric_transitions_with_rate \
          :Euler_action_vector_for_stoichiometric_transitions_with_rate
    alias :Euler_action_vector_for_SR_transitions \
          :Euler_action_vector_for_stoichiometric_transitions_with_rate
    alias :euler_action_vector_for_SR_transitions \
          :Euler_action_vector_for_SR_transitions
    alias :Euler_𝖆_for_stoichiometric_transitions_with_rate \
          :euler_action_vector_for_SR_transitions
    alias :Euler_𝖆_for_SR_transitions \
          :euler_action_vector_for_SR_transitions
    alias :euler_𝖆_for_SR_transitions \
          :euler_action_vector_for_SR_transitions

    # Euler action fro SR transitions as has with tr. name symbols as keys.
    def Euler_action_for_SR_tt_sym( Δt )
      stoichiometric_ttß_ :Euler_action_vector_for_SR_transitions, Δt
    end
    alias :euler_action_for_SR_tt_sym :Euler_action_for_SR_tt_sym
    alias :Euler_action_for_SR_ttß :Euler_action_for_SR_tt_sym
    alias :euler_action_for_SR_ttß :euler_action_for_SR_tt_sym

    # Convenience calculator of Δ state for SR transitions, assuming a single
    # Eulerian step with Δt given as parameter.
    def Δ_Euler_for_stoichiometric_transitions_with_rate( Δt )
      ∂_for_SR_transitions * Δt
    end
    alias :Δ_euler_for_stoichiometric_transitions_with_rate \
          :Δ_Euler_for_stoichiometric_transitions_with_rate
    alias :Δ_Euler_for_SR_transitions \
          :Δ_Euler_for_stoichiometric_transitions_with_rate
    alias :Δ_euler_for_SR_transitions :Δ_Euler_for_SR_transitions

    # Δ state for SR transitions under Eulerian step with Δt as parameter,
    # returning a hash with free place symbols as keys
    def Δ_Euler_for_SR_tt_sym( Δt )
      free_ppß_ :Δ_Euler_for_SR_transitions, Δt
    end
    alias :Δ_euler_for_SR_tt_sym :Δ_Euler_for_SR_tt_sym
    alias :Δ_Euler_for_SR_ttß :Δ_Euler_for_SR_tt_sym
    alias :Δ_euler_for_SR_ttß :Δ_Euler_for_SR_tt_sym

    # ----------------------------------------------------------------------
    # Sparse stoichiometry vectors for transitions

    # For a transition specified by the argument, this method returns a sparse
    # stoichiometry vector mapped to free places of the simulation.
    def sparse_stoichiometry_vector tr; t = transition( tr )
      raise AE, "Transition #{tr} not stoichiometric!" unless t.stoichiometric?
      Matrix.correspondence_matrix( t.codomain, free_places ) *
        Matrix.column_vector( t.stoichiometry )
    end
    alias :sparse_𝖘 :sparse_stoichiometry_vector
    
    # For a transition specified by the argument, this method returns a sparse
    # stoichiometry vector mapped to all the places of the simulation.
    def sparse_stoichiometry_vector! tr; t = transition( tr )
      raise AE, "Transition #{tr} not stoichiometric!" unless t.stoichiometric?
      Matrix.correspondence_matrix( t.codomain, places ) *
        Matrix.column_vector( t.stoichiometry )
    end
    alias :sparse_𝖘! :sparse_stoichiometry_vector!

    # Correspondence matrix free places => all places
    attr_reader :free_places_to_all_places_matrix
    alias :f2p_matrix :free_places_to_all_places_matrix
    # Correspondence matrix clamped places => all places
    attr_reader :clamped_places_to_all_places_matrix
    alias :c2p_matrix :clamped_places_to_all_places_matrix

    private

    # These two provide typesafe access to places & transitions
    delegate :place, :transition, to: :net

    # Resets the simulation
    def reset!
      zero_vector = Matrix.column_vector( places.map {0.0} ) # Float zeros
      clamped_component = clamped_places_to_all_places_matrix *
        compute_marking_vector_of_clamped_places
      free_component = free_places_to_all_places_matrix *
        compute_initial_marking_vector_of_free_places
      @marking_vector = zero_vector + clamped_component + free_component
      reset_recording!
      note_state_change!
      return self
    end

    # Resets the recording
    def reset_recording!; @recording = {} end

    # To be called whenever the state changes. The method will cogitate, whether
    # the observed state change warrants calling #sample!
    def note_state_change!
      sample! # default for vanilla Simulation: sample! at every occasion
    end
    
    # Does sampling into @recording, which is a hash of pairs
    # { sampling_event => simulation state }
    def sample! key=ℒ(:sample!)
      @sample_number = @sample_number + 1 rescue 0
      @recording[ key.ℓ?(:sample!) ? @sample_number : key ] =
        marking_array!.map { |num| num.round SAMPLING_DECIMAL_PLACES }
    end

    # Called upon initialzation
    def compute_initial_marking_vector_of_free_places
      Matrix.column_vector( free_places.map { |p| @initial_marking[p] }
                              .map { |im|
                                im = im.value rescue im # try #value
                                im.call rescue im       # try #call
                              # the above unwraps place and/or closure
                             } )
    end

    # Called upon initialization
    def compute_marking_vector_of_clamped_places
      Matrix.column_vector( clamped_places.map { |p| @place_clamps[p] }
                              .map { |clamp|
                                clamp = clamp.value rescue clamp # try #value
                                clamp.call rescue clamp          # try #call
                              # the above unwraps place and/or closure
                            } )
    end

    # Expects a Δ marking vector for free places and performs the specified
    # change on the marking vector for all places.
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
        λ { c2f * t.action_closure.( *( p2d * 𝖒! ).column_to_a ) }
      }
    end

    def create_delta_state_closures_for_timed_rateless_nonstoichiometric_transitions
      timed_rateless_nonstoichiometric_transitions.map { |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        c2f = Matrix.correspondence_matrix( t.codomain, free_places )
        λ { |Δt| c2f * t.action_closure.( Δt, *( p2d * 𝖒! ).column_to_a ) }
      }
    end

    def create_action_closures_for_timeless_stoichiometric_transitions
      timeless_stoichiometric_transitions.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { t.action_closure.( *( p2d * 𝖒! ).column_to_a ) }
      }
    end

    def create_action_closures_for_timed_rateless_stoichiometric_transitions
      timed_rateless_stoichiometric_transitions.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { |Δt| t.action_closure.( Δt, *( p2d * 𝖒! ).column_to_a ) }
      }
    end

    def create_rate_closures_for_nonstoichiometric_transitions_with_rate
      nonstoichiometric_transitions_with_rate.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        c2f = Matrix.correspondence_matrix( t.codomain, free_places )
        λ { c2f * t.rate_closure.( *( p2d * 𝖒! ).column_to_a ) }
      }
    end

    def create_rate_closures_for_stoichiometric_transitions_with_rate
      stoichiometric_transitions_with_rate.map{ |t|
        p2d = Matrix.correspondence_matrix( places, t.domain )
        λ { t.rate_closure.( *( p2d * 𝖒! ).column_to_a ) }
      }
    end
  end # class Simulation
end # module YPetri
