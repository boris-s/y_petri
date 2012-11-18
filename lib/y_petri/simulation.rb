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

    # Exposing @initial_marking (hash with place instances as keys)
    attr_accessor :initial_marking

    # Initial marking hash with place name symbols as keys
    def im
      initial_marking.with_keys { |k| k.name.nil? ? k : k.name.to_sym }
    end

    # Initial marking as array corresponding to free places
    def initial_marking_array; free_places.map { |p| initial_marking[p] } end

  end # class Simulation
end # module YPetri
