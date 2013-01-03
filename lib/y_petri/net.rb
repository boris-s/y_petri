#encoding: utf-8

module YPetri

  # Represents a <em>Petri net</em>: A collection of places and
  # transitions. The connector arrows – called <em>arcs</em> in
  # classical Petri net terminology – are considered a property
  # of transitions. In <tt>YPetri</tt>, 'arcs' is a synonym for
  # places / transitions connected to a given transition / place.
  # 
  class Net
    include NameMagic

    def initialize *args; oo = args.extract_options!
      @places, @transitions = [], [] # empty arrays
      # LATER: let the places/transitions be specified upon init
    end

    attr_reader :places, :transitions

    # Names of places in the net.
    # 
    def pp; places.map &:name end

    # Names of transitions in the net.
    # 
    def tt; transitions.map &:name end
    
    # Includes a place in the net. Returns <em>true</em> if successful,
    # <em>false</em> if the place is already included in the net.
    # 
    def include_place! place
      p = place( place )
      return false if @places.include? p
      @places << p
      return true
    end

    # Includes a transition in the net. Returns <em>true</em> if successful,
    # <em>false</em> if the transition is already included in the net. The
    # arcs of the transition being included may only connect to the places
    # already in the net.
    # 
    def include_transition! transition;
      t = transition( transition )
      return false if @transitions.include? t
      raise TypeError, "Unable to include the transition #{t} in #{self}: " +
        "It connects to one or more places outside the net." unless
        t.arcs.all? { |p| include? p }
      @transitions << t
      return true
    end

    # Excludes a place from the net. Returns <em>true<em> if successful,
    # <em>false</em> if the place was not found in the net. A place may
    # not be excluded from the net so long as any transitions in the
    # net connect to it.
    # 
    def exclude_place! place
      p = place( place )
      raise "Unable to exclude #{p} from #{self}: One or more transitions" +
        "depend on it" if transitions.any? { |t| t.arcs.include? p }
      return true if @places.delete p
      return false
    end

    # Excludes a transition from the net. Returns <em>true</em> if successful,
    # <em>false</em> if the transition was not found in the net.
    # 
    def exclude_transition! transition
      t = transition( transition )
      return true if @transitions.delete t
      return false
    end

    # Includes an object (either place or transition) in the net. Acts by
    # calling #include_place! or #include_transition!, as needed, the
    # difference being, that errors from bad arguments are swallowed.
    # 
    def << place_or_transition
      begin
        include_place!( place_or_transition )
      rescue NameError
        begin
          include_transition!( place_or_transition )
        rescue NameError
          raise NameError,
                "Unrecognized place or transition: #{place_or_transition}"
        end
      end
      return self
    end

    # Inquirer whether the net includes a place / transition.
    # 
    def include? place_or_transition
      p = begin
            place( place_or_transition )
          rescue NameError
            nil
          end
      if p then return places.include? p end
      t = begin
            transition( place_or_transition )
          rescue NameError
            nil
          end
      if t then return transitions.include? t end
      return false
    end

    # ----------------------------------------------------------------------
    # Methods exposing transition collections acc. to their properties:

    # Array of <em>ts</em> transitions in the net.
    # 
    def timeless_nonstoichiometric_transitions
      transitions.select{ |t| t.timeless? and t.nonstoichiometric? }
    end
    alias :ts_transitions :timeless_nonstoichiometric_transitions
    
    # Names of <em>ts</em> transitions in the net.
    # 
    def timeless_nonstoichiometric_tt
      timeless_nonstoichiometric_transitions.map &:name
    end
    alias :ts_tt :timeless_nonstoichiometric_tt

    # Array of <em>tS</em> transitions in the net.
    # 
    def timeless_stoichiometric_transitions
      transitions.select{ |t| t.timeless? and t.stoichiometric? }
    end
    alias :tS_transitions :timeless_stoichiometric_transitions

    # Names of <em>tS</em> transitions in the net.
    # 
    def timeless_stoichiometric_tt
      timeless_stoichiometric_transitions.map &:name
    end
    alias :tS_tt :timeless_stoichiometric_tt

    # Array of <em>Tsr</em> transitions in the net.
    # 
    def timed_nonstoichiometric_transitions_without_rate
      transitions.select{ |t| t.timed? and t.nonstoichiometric? and t.rateless? }
    end
    alias :timed_rateless_nonstoichiometric_transitions \
          :timed_nonstoichiometric_transitions_without_rate
    alias :Tsr_transitions :timed_nonstoichiometric_transitions_without_rate

    # Names of <em>Tsr</em> transitions in the net.
    # 
    def timed_nonstoichiometric_tt_without_rate
      timed_nonstoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_nonstoichiometric_tt \
          :timed_nonstoichiometric_tt_without_rate
    alias :Tsr_tt :timed_nonstoichiometric_tt_without_rate

    # Array of <em>TSr</em> transitions in the net.
    # 
    def timed_stoichiometric_transitions_without_rate
      transitions.select { |t| t.timed? and t.stoichiometric? and t.rateless? }
    end
    alias :timed_rateless_stoichiometric_transitions \
          :timed_stoichiometric_transitions_without_rate
    alias :TSr_transitions :timed_stoichiometric_transitions_without_rate

    # Names of <em>TSr</em> transitions in the net.
    # 
    def timed_stoichiometric_tt_without_rate
      timed_stoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_stoichiometric_tt :timed_stoichiometric_tt_without_rate
    alias :Tsr_tt :timed_stoichiometric_tt_without_rate

    # Array of <em>sR</em> transitions in the net.
    # 
    def nonstoichiometric_transitions_with_rate
      transitions.select { |t| t.has_rate? and t.nonstoichiometric? }
    end
    alias :sR_transitions :nonstoichiometric_transitions_with_rate

    # Names of <em>sR</em> transitions in the net.
    # 
    def nonstoichiometric_tt_with_rate
      nonstoichiometric_transitions_with_rate.map &:name
    end
    alias :sR_tt :nonstoichiometric_tt_with_rate

    # Array of <em>SR</em> transitions in the net.
    # 
    def stoichiometric_transitions_with_rate
      transitions.select { |t| t.has_rate? and t.stoichiometric? }
    end
    alias :SR_transitions :stoichiometric_transitions_with_rate

    # Names of <em>SR</em> transitions in the net.
    # 
    def stoichiometric_tt_with_rate
      stoichiometric_transitions_with_rate.map &:name
    end
    alias :SR_tt :stoichiometric_tt_with_rate

    # Array of transitions with <em>explicit assignment action</em>
    # (<em>A</em> transitions) in the net.
    # 
    def transitions_with_explicit_assignment_action
      transitions.select { |t| t.assignment_action? }
    end
    alias :transitions_with_assignment_action \
          :transitions_with_explicit_assignment_action
    alias :assignment_transitions :transitions_with_explicit_assignment_action
    alias :A_transitions :transitions_with_explicit_assignment_action

    # Names of transitions with <em>explicit assignment action</em>
    # (<em>A</em> transitions) in the net.
    # 
    def tt_with_explicit_assignment_action
      transitions_with_explicit_assignment_action.map &:name
    end
    alias :tt_with_assignment_action :tt_with_explicit_assignment_action
    alias :assignment_tt :tt_with_assignment_action
    alias :A_tt :tt_with_assignment_action

    # Array of <em>stoichiometric</em> transitions in the net.
    # 
    def stoichiometric_transitions
      transitions.select &:stoichiometric?
    end
    alias :S_transitions :stoichiometric_transitions

    # Names of <em>stoichiometric</em> transitions in the net.
    # 
    def stoichiometric_tt
      stoichiometric_transitions.map &:name
    end
    alias :S_tt :stoichiometric_tt

    # Array of <em>nonstoichiometric</em> transitions in the net.
    # 
    def nonstoichiometric_transitions
      transitions.select &:nonstoichiometric?
    end
    alias :s_transitions :nonstoichiometric_transitions

    # Names of <em>nonstoichimetric</em> transitions in the net.
    # 
    def nonstoichiometric_tt
      nonstoichiometric_transitions.map &:name
    end
    alias :s_tt :nonstoichiometric_tt

    # Array of <em>timed</em> transitions in the net.
    #
    def timed_transitions; transitions.select &:timed? end
    alias :T_transitions :timed_transitions

    # Names of <em>timed</em> transitions in the net.
    # 
    def timed_tt; timed_transitions.map &:name end
    alias :T_tt :timed_tt

    # Array of <em>timeless</em> transitions in the net.
    # 
    def timeless_transitions; transitions.select &:timeless? end
    alias :t_transitions :timeless_transitions

    # Names of <em>timeless</em> transitions in the net.
    # 
    def timeless_tt; timeless_transitions.map &:name end
    alias :t_tt :timeless_tt

    # Array of <em>transitions with rate</em> in the net.
    # 
    def transitions_with_rate; transitions.select &:has_rate? end
    alias :R_transitions :transitions_with_rate

    # Names of <em>transitions with rate</em> in the net.
    # 
    def tt_with_rate; transitions_with_rate.map &:name end
    alias :R_tt :tt_with_rate

    # Array of <em>rateless</em> transitions in the net.
    # 
    def rateless_transitions; transitions.select &:rateless? end
    alias :transitions_without_rate :rateless_transitions
    alias :r_transitions :rateless_transitions

    # Names of <em>rateless</em> transitions in the net.
    # 
    def rateless_tt; rateless_transitions.map &:name end
    alias :tt_without_rate :rateless_tt
    alias :r_tt :rateless_tt

    # ==== Inquirer methods about net qualities

    # Is the net <em>functional</em>?
    # 
    def functional?; transitions.all? { |t| t.functional? } end
    
    # Is the net <em>timed</em>?
    # 
    def timed?; transitions.all? { |t| t.timed? } end

    # ==== Simulation constructors

    # Creates a new simulation from the net.
    # 
    def new_simulation *args; oo = args.extract_options!
      YPetri::Simulation.new *args, oo.merge( net: self )
    end

    # Creates a new timed simulation from the net.
    # 
    def new_timed_simulation *args; oo = args.extract_options!
      YPetri::TimedSimulation.new oo.merge( net: self )
    end

    # ==== Sundry methods

    # Networks are equal when their places and transitions are equal.
    # 
    def == other
      return false unless other.class_complies?( ç )
      places == other.places && transitions == other.transitions
    end

    def to_s                         # :nodoc:
      "Net[ #{places.size} places, #{transitions.size} transitions ]"
    end

    def inspect                      # :nodoc:
      "#<Net: #{name.nil? ? '' : name + ': '} #{self.pp.size} places, " +
        "#{tt.size} transitions" +
        "#{name.nil? ? ', object id: %s' % object_id : ''} >"
    end

    private

    # Place, Transition, Net class
    # 
    def Place; ::YPetri::Place end
    def Transition; ::YPetri::Transition end
    def Net; ::YPetri::Net end

    # Instance identification methods.
    # 
    def place( which ); Place().instance( which ) end
    def transition( which ); Transition().instance( which ) end
    def net( which ); Net().instance( which ) end
  end # class Net
end # module YPetri
