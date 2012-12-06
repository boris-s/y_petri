#encoding: utf-8

# YPetri::Net represents a Petri net: A collection of places and
# transitions. The connector arrows are considered a property of a
# transition, and 'arcs' is a synonym for 'places connected to a
# transition'.

module YPetri
  class Net
    include NameMagic
    
    def initialize *args; oo = args.extract_options!
      @places, @transitions = [], [] # empty arrays so far
      # LATER: let the places/transitions be specified upon init
    end
    
    attr_reader :places, :transitions
    def pp; places.map &:name end
    def tt; transitions.map &:name end
    
    # Includes a place in the net.
    def include_place! p; p = ::YPetri::Place( p )
      return false if @places.include? p
      @places << p
      return true
    end

    # Includes a transition in the net.
    def include_transition! t; t = ::YPetri::Transition( t )
      return false if @transitions.include? t
      raise "Unable to include the transition in the net: It connects to one " +
        "or more places outside the net. Include the places first." unless
        t.arcs.all? { |p| include? p }
      @transitions << t
      return true
    end

    # Excludes a place from the net.
    def exclude_place! p; p = ::YPetri::Place( p )
      raise "Unable to exclude the place from the net: One or more " +
        "transitions depend on it" if
        transitions.any? { |t| t.arcs.include? p }
      return true if @places.delete p
      return false
    end

    def exclude_transition! t; t = ::YPetri::Transition( t )
      return true if @transitions.delete t
      return false
    end

    # Includes a place / transition in the net.
    def << e
      begin
        include_place!( e )
      rescue ArgumentError
        begin
          include_transition!( e )
        rescue ArgumentError
        end
      ensure
        return self
      end
    end

    # Whether the net includes a place / transition.
    def include? e
      not not place( e ) rescue not not transition( e ) rescue return false
    end

    # ----------------------------------------------------------------------
    # Methods exposing transition collections acc. to their properties:

    def timeless_nonstoichiometric_transitions
      transitions.select{ |t| t.timeless? and t.nonstoichiometric? }
    end
    alias :ts_transitions :timeless_nonstoichiometric_transitions
    
    def timeless_nonstoichiometric_tt
      timeless_nonstoichiometric_transitions.map &:name
    end
    alias :ts_tt :timeless_nonstoichiometric_tt

    def timeless_stoichiometric_transitions
      transitions.select{ |t| t.timeless? and t.stoichiometric? }
    end
    alias :tS_transitions :timeless_stoichiometric_transitions

    def timeless_stoichiometric_tt
      timeless_stoichiometric_transitions.map &:name
    end
    alias :tS_tt :timeless_stoichiometric_tt

    def timed_nonstoichiometric_transitions_without_rate
      transitions.select{ |t| t.timed? and t.nonstoichiometric? and t.rateless? }
    end
    alias :timed_rateless_nonstoichiometric_transitions \
          :timed_nonstoichiometric_transitions_without_rate
    alias :Tsr_transitions :timed_nonstoichiometric_transitions_without_rate

    def timed_nonstoichiometric_tt_without_rate
      timed_nonstoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_nonstoichiometric_tt \
          :timed_nonstoichiometric_tt_without_rate
    alias :Tsr_tt :timed_nonstoichiometric_tt_without_rate

    def timed_stoichiometric_transitions_without_rate
      transitions.select { |t| t.timed? and t.stoichiometric? and t.rateless? }
    end
    alias :timed_rateless_stoichiometric_transitions \
          :timed_stoichiometric_transitions_without_rate
    alias :TSr_transitions :timed_stoichiometric_transitions_without_rate

    def timed_stoichiometric_tt_without_rate
      timed_stoichiometric_transitions_without_rate.map &:name
    end
    alias :timed_rateless_stoichiometric_tt :timed_stoichiometric_tt_without_rate
    alias :Tsr_tt :timed_stoichiometric_tt_without_rate

    def nonstoichiometric_transitions_with_rate
      transitions.select { |t| t.has_rate? and t.nonstoichiometric? }
    end
    alias :sR_transitions :nonstoichiometric_transitions_with_rate

    def nonstoichiometric_tt_with_rate
      nonstoichiometric_transitions_with_rate.map &:name
    end
    alias :sR_tt :nonstoichiometric_tt_with_rate

    def stoichiometric_transitions_with_rate
      transitions.select { |t| t.has_rate? and t.stoichiometric? }
    end
    alias :SR_transitions :stoichiometric_transitions_with_rate

    def stoichiometric_tt_with_rate
      stoichiometric_transitions_with_rate.map &:name
    end
    alias :SR_tt :stoichiometric_tt_with_rate

    def transitions_with_explicit_assignment_action
      transitions.select { |t| t.assignment_action? }
    end
    alias :transitions_with_assignment_action \
          :transitions_with_explicit_assignment_action
    alias :assignment_transitions :transitions_with_explicit_assignment_action
    alias :A_transitions :transitions_with_explicit_assignment_action

    def tt_with_explicit_assignment_action
      transitions_with_explicit_assignment_action.map &:name
    end
    alias :tt_with_assignment_action :tt_with_explicit_assignment_action
    alias :assignment_tt :tt_with_assignment_action
    alias :A_tt :tt_with_assignment_action

    def stoichiometric_transitions; transitions.select &:stoichiometric? end
    alias :S_transitions :stoichiometric_transitions
    def stoichiometric_tt; stoichiometric_transitions.map &:name end
    alias :S_tt :stoichiometric_tt

    def nonstoichiometric_transitions; transitions.select &:nonstoichiometric? end
    alias :s_transitions :nonstoichiometric_transitions
    def nonstoichiometric_tt; nonstoichiometric_transitions.map &:name end
    alias :s_tt :nonstoichiometric_tt

    def timed_transitions; transitions.select &:timed? end
    alias :T_transitions :timed_transitions
    def timed_tt; timed_transitions.map &:name end
    alias :T_tt :timed_tt

    def timeless_transitions; transitions.select &:timeless? end
    alias :t_transitions :timeless_transitions
    def timeless_tt; timeless_transitions.map &:name end
    alias :t_tt :timeless_tt

    def transitions_with_rate; transitions.select &:has_rate? end
    alias :R_transitions :transitions_with_rate
    def tt_with_rate; transitions_with_rate.map &:name end
    alias :R_tt :tt_with_rate

    def rateless_transitions; transitions.select &:rateless? end
    alias :transitions_without_rate :rateless_transitions
    alias :r_transitions :rateless_transitions

    def rateless_tt; rateless_transitions.map &:name end
    alias :tt_without_rate :rateless_tt
    alias :r_tt :rateless_tt

    # ----------------------------------------------------------------------
    # Inquirer methods about net qualities

    # Is the net functional?
    def functional?; transitions.all? { |t| t.functional? } end
    
    # Is the net timed?
    def timed?; transitions.all? { |t| t.timed? } end

    # ----------------------------------------------------------------------
    # Safe access to places & transitions

    # Safe access to the place instances included in this net.
    def place arg
      ::YPetri::Place( arg ).tap { |instance|
        raise AE, "Place #{arg} not included in this net." unless
          @places.include? instance }
    end
    
    # Safe access to the transition instances included in this net.
    def transition arg
      ::YPetri::Transition( arg ).tap { |instance|
        raise AE, "Transition #{arg} not included in this net." unless
          @transitions.include? instance }
    end

    # ----------------------------------------------------------------------
    # Simulation and timed simulation constructors

    # Creates a new simulation from the net.
    def new_simulation *aa; oo = aa.extract_options!
      YPetri::Simulation.new *aa, oo.merge( net: self ) end

    # Creates a new timed simulation from the net.
    def new_timed_simulation *aa; oo = aa.extract_options!
      YPetri::TimedSimulation.new oo.merge( net: self ) end

    # ----------------------------------------------------------------------
    # "Standard equipment" methods

    # #==
    def == other
      return false unless other.declares_module_compliance?( ç )
      places == other.places && transitions == other.transitions
    end

    # #inspect
    def inspect
      "YPetri::Net[ #{name.nil? ? '' : name + ': '} #{pp.size} places, " +
        "#{tt.size} transitions" +
        "#{name.nil? ? ', object id: %s' % object_id : ''} ]"
    end

    # #to_s
    def to_s
      "Net[ #{places.size} places, #{transitions.size} transitions ]"
    end
  end # class Net
end # module YPetri
