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

  end # class Simulation
end # module YPetri
