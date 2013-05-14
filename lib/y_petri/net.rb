#encoding: utf-8

# Represents a <em>Petri net</em>: A collection of places and
# transitions. The connector arrows – called <em>arcs</em> in
# classical Petri net terminology – are considered a property
# of transitions. In <tt>YPetri</tt>, 'arcs' is a synonym for
# places / transitions connected to a given transition / place.
# 
class YPetri::Net
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
    pl = place( place )
    return false if @places.include? pl
    @places << pl
    return true
  end

  # Includes a transition in the net. Returns <em>true</em> if successful,
  # <em>false</em> if the transition is already included in the net. The
  # arcs of the transition being included may only connect to the places
  # already in the net.
  # 
  def include_transition! transition;
    tr = transition( transition )
    return false if @transitions.include? tr
    raise TypeError, "Unable to include the transition #{tr} in #{self}: " +
      "It connects to one or more places outside the net." unless
      tr.arcs.all? { |pl| include? pl }
    @transitions << tr
    return true
  end

  # Excludes a place from the net. Returns <em>true<em> if successful,
  # <em>false</em> if the place was not found in the net. A place may
  # not be excluded from the net so long as any transitions in the
  # net connect to it.
  # 
  def exclude_place! place
    pl = place( place )
    raise "Unable to exclude #{pl} from #{self}: One or more transitions" +
      "depend on it" if transitions.any? { |tr| tr.arcs.include? pl }
    return true if @places.delete pl
    return false
  end

  # Excludes a transition from the net. Returns <em>true</em> if successful,
  # <em>false</em> if the transition was not found in the net.
  # 
  def exclude_transition! transition
    tr = transition( transition )
    return true if @transitions.delete tr
    return false
  end

  # Includes an object (either place or transition) in the net. Acts by
  # calling #include_place! or #include_transition!, as needed, the
  # difference being, that errors from bad arguments are swallowed.
  # 
  def << place_or_transition
    begin
      include_place! place_or_transition
    rescue NameError
      begin
        include_transition! place_or_transition
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
    pl = begin
           place( place_or_transition )
         rescue NameError
           nil
         end
    return places.include? pl if pl
    tr = begin
           transition( place_or_transition )
         rescue NameError
           nil
         end
    return transitions.include? tr if tr
    return false
  end

  # ----------------------------------------------------------------------
  # Methods exposing transition collections acc. to their properties:

  # Array of <em>ts</em> transitions in the net.
  # 
  def timeless_nonstoichiometric_transitions
    transitions.select { |t| t.timeless? && t.nonstoichiometric? }
  end
  alias ts_transitions timeless_nonstoichiometric_transitions

  # Names of <em>ts</em> transitions in the net.
  # 
  def timeless_nonstoichiometric_tt
    timeless_nonstoichiometric_transitions.map &:name
  end
  alias ts_tt timeless_nonstoichiometric_tt

  # Array of <em>tsa</em> transitions in the net.
  # 
  def timeless_nonstoichiometric_nonassignment_transitions
    transitions.select { |t|
      t.timeless? && t.nonstoichiometric? && ! t.assignment_action?
    }
  end
  alias tsa_transitions timeless_nonstoichiometric_nonassignment_transitions

  # Names of <em>tsa</em> transitions in the net.
  # 
  def timeless_nonstoichiometric_nonassignment_tt
    timeless_nonstoichiometric_nonassignment_transitions.map &:name
  end
  alias tsa_tt timeless_nonstoichiometric_nonassignment_tt

  # Array of <em>tS</em> transitions in the net.
  # 
  def timeless_stoichiometric_transitions
    transitions.select { |t| t.timeless? && t.stoichiometric? }
  end
  alias tS_transitions timeless_stoichiometric_transitions

  # Names of <em>tS</em> transitions in the net.
  # 
  def timeless_stoichiometric_tt
    timeless_stoichiometric_transitions.map &:name
  end
  alias tS_tt timeless_stoichiometric_tt

  # Array of <em>Tsr</em> transitions in the net.
  # 
  def timed_nonstoichiometric_transitions_without_rate
    transitions.select { |t| t.timed? && t.nonstoichiometric? && t.rateless? }
  end
  alias timed_rateless_nonstoichiometric_transitions \
        timed_nonstoichiometric_transitions_without_rate
  alias Tsr_transitions timed_nonstoichiometric_transitions_without_rate

  # Names of <em>Tsr</em> transitions in the net.
  # 
  def timed_nonstoichiometric_tt_without_rate
    timed_nonstoichiometric_transitions_without_rate.map &:name
  end
  alias timed_rateless_nonstoichiometric_tt \
        timed_nonstoichiometric_tt_without_rate
  alias Tsr_tt timed_nonstoichiometric_tt_without_rate

  # Array of <em>TSr</em> transitions in the net.
  # 
  def timed_stoichiometric_transitions_without_rate
    transitions.select { |t| t.timed? && t.stoichiometric? && t.rateless? }
  end
  alias timed_rateless_stoichiometric_transitions \
        timed_stoichiometric_transitions_without_rate
  alias TSr_transitions timed_stoichiometric_transitions_without_rate

  # Names of <em>TSr</em> transitions in the net.
  # 
  def timed_stoichiometric_tt_without_rate
    timed_stoichiometric_transitions_without_rate.map &:name
  end
  alias timed_rateless_stoichiometric_tt timed_stoichiometric_tt_without_rate
  alias Tsr_tt timed_stoichiometric_tt_without_rate

  # Array of <em>sR</em> transitions in the net.
  # 
  def nonstoichiometric_transitions_with_rate
    transitions.select { |t| t.has_rate? && t.nonstoichiometric? }
  end
  alias sR_transitions nonstoichiometric_transitions_with_rate

  # Names of <em>sR</em> transitions in the net.
  # 
  def nonstoichiometric_tt_with_rate
    nonstoichiometric_transitions_with_rate.map &:name
  end
  alias sR_tt nonstoichiometric_tt_with_rate

  # Array of <em>SR</em> transitions in the net.
  # 
  def stoichiometric_transitions_with_rate
    transitions.select { |t| t.has_rate? and t.stoichiometric? }
  end
  alias SR_transitions stoichiometric_transitions_with_rate

  # Names of <em>SR</em> transitions in the net.
  # 
  def stoichiometric_tt_with_rate
    stoichiometric_transitions_with_rate.map &:name
  end
  alias SR_tt stoichiometric_tt_with_rate

  # Array of transitions with <em>explicit assignment action</em>
  # (<em>A</em> transitions) in the net.
  # 
  def assignment_transitions
    transitions.select { |t| t.assignment_action? }
  end
  alias A_transitions assignment_transitions

  # Names of transitions with <em>explicit assignment action</em>
  # (<em>A</em> transitions) in the net.
  # 
  def assignment_tt
    assignment_transitions.map &:name
  end
  alias A_tt assignment_tt

  # Array of <em>stoichiometric</em> transitions in the net.
  # 
  def stoichiometric_transitions
    transitions.select &:stoichiometric?
  end
  alias S_transitions stoichiometric_transitions

  # Names of <em>stoichiometric</em> transitions in the net.
  # 
  def stoichiometric_tt
    stoichiometric_transitions.map &:name
  end
  alias S_tt stoichiometric_tt

  # Array of <em>nonstoichiometric</em> transitions in the net.
  # 
  def nonstoichiometric_transitions
    transitions.select &:nonstoichiometric?
  end
  alias s_transitions nonstoichiometric_transitions

  # Names of <em>nonstoichimetric</em> transitions in the net.
  # 
  def nonstoichiometric_tt
    nonstoichiometric_transitions.map &:name
  end
  alias s_tt nonstoichiometric_tt

  # Array of <em>timed</em> transitions in the net.
  #
  def timed_transitions; transitions.select &:timed? end
  alias T_transitions timed_transitions

  # Names of <em>timed</em> transitions in the net.
  # 
  def timed_tt; timed_transitions.map &:name end
  alias T_tt timed_tt

  # Array of <em>timeless</em> transitions in the net.
  # 
  def timeless_transitions; transitions.select &:timeless? end
  alias t_transitions timeless_transitions

  # Names of <em>timeless</em> transitions in the net.
  # 
  def timeless_tt; timeless_transitions.map &:name end
  alias t_tt timeless_tt

  # Array of <em>transitions with rate</em> in the net.
  # 
  def transitions_with_rate; transitions.select &:has_rate? end
  alias R_transitions transitions_with_rate

  # Names of <em>transitions with rate</em> in the net.
  # 
  def tt_with_rate; transitions_with_rate.map &:name end
  alias R_tt tt_with_rate

  # Array of <em>rateless</em> transitions in the net.
  # 
  def rateless_transitions; transitions.select &:rateless? end
  alias transitions_without_rate rateless_transitions
  alias r_transitions rateless_transitions

  # Names of <em>rateless</em> transitions in the net.
  # 
  def rateless_tt; rateless_transitions.map &:name end
  alias tt_without_rate rateless_tt
  alias r_tt rateless_tt

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
  def new_simulation *args
    oo = args.extract_options!
    YPetri::Simulation.new *args, oo.merge( net: self )
  end

  # Creates a new timed simulation from the net.
  # 
  def new_timed_simulation *args
    oo = args.extract_options!
    YPetri::TimedSimulation.new oo.merge( net: self )
  end

  # ==== Sundry methods

  # Networks are equal when their places and transitions are equal.
  # 
  def == other
    return false unless other.class_complies?( ç )
    places == other.places && transitions == other.transitions
  end

  # Returns a string briefly describing the net.
  # 
  def to_s
    "#<Net: " + ( name.nil? ? "%s" : "name: #{name}, %s" ) %
      "#{places.size} places, #{transitions.size} transitions" + " >"
  end

  def visualize
    require 'graphviz'
    γ = GraphViz.new :G
    # Add places and transitions.
    place_nodes = places.map.with_object Hash.new do |pl, ꜧ|
      ꜧ[pl] = γ.add_nodes pl.name.to_s,
                          fillcolor: 'lightgrey',
                          color: 'grey',
                          style: 'filled'
    end
    transition_nodes = transitions.map.with_object Hash.new do |tr, ꜧ|
      ꜧ[tr] = γ.add_nodes tr.name.to_s,
                          shape: 'box',
                          fillcolor: if tr.assignment? then 'yellow'
                                     elsif tr.basic_type == :SR then 'lightcyan'
                                     else 'ghostwhite' end,
                          color: if tr.assignment? then 'goldenrod'
                                 elsif tr.basic_type == :SR then 'cyan'
                                 else 'grey' end,
                          style: 'filled'
    end
    # Add Petri net arcs.
    transition_nodes.each { |tr, tr_node|
      if tr.assignment? then
        tr.codomain.each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'goldenrod'
        }
        ( tr.domain - tr.codomain ).each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      elsif tr.basic_type == :SR then
        tr.codomain.each { |pl|
          if tr.stoichio[pl] > 0 then # producing arc
            γ.add_edges tr_node, place_nodes[pl], color: 'cyan'
          elsif tr.stoichio[pl] < 0 then # consuming arc
            γ.add_edges place_nodes[pl], tr_node, color: 'cyan'
          else
            γ.add_edges place_nodes[pl], tr_node, color: 'grey', arrowhead: 'none'
          end
        }
        ( tr.domain - tr.codomain ).each { |pl|
          γ.add_edges tr_node, place_nodes[pl], color: 'grey', arrowhead: 'none'
        }
      end
    }
    # Generate output image.
    γ.output png: File.expand_path( "~/y_petri_graph.png" )
    # require 'y_support/kde'
    YSupport::KDE.show_file_with_kioclient File.expand_path( "~/y_petri_graph.png" )
  end

  # Inspect string of the instance.
  # 
  def inspect; to_s end

  private

  # Display a file with kioclient (KDE).
  # 
  def show_file_with_kioclient( file_name )
    system "sleep 0.2; kioclient exec 'file:%s'" %
      File.expand_path( '.', file_name )
  end

  # Place, Transition, Net classes.
  # 
  def Place; ::YPetri::Place end
  def Transition; ::YPetri::Transition end
  def Net; ::YPetri::Net end

  # Instance identification methods.
  # 
  def place( which ); Place().instance( which ) end
  def transition( which ); Transition().instance( which ) end
  def net( which ); Net().instance( which ) end
end # class YPetri::Net
