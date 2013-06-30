#encoding: utf-8

require_relative 'dependency_injection'
require_relative 'net/visualization'
require_relative 'net/selections'

# Represents a _Petri net_: A collection of places and transitions. The
# connector arrows – called _arcs_ in classical Petri net terminology – can be
# considered a property of transitions. Therefore in +YPetri+, term 'arcs' is
# mostly used as a synonym  denoting neighboring places / transitions.
# 
class YPetri::Net
  include NameMagic
  include YPetri::DependencyInjection
  
  attr_reader :places, :transitions

  def initialize( places: [], transitions: [] )
    @places, @transitions = places, transitions
  end

  # Includes a place in the net. Returns _true_ if successful, _false_ if the
  # place is already included in the net.
  # 
  def include_place! place
    pl = place( place )
    return false if @places.include? pl
    @places << pl
    return true
  end

  # Includes a transition in the net. Returns _true_ if successful, _false_ if
  # the transition is already included in the net. The arcs of the transition
  # being included may only connect to the places already in the net.
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

  # Excludes a place from the net. Returns _true_ if successful, _false_ if the
  # place was not found in the net. A place may not be excluded from the net so
  # long as any transitions in the net connect to it.
  # 
  def exclude_place! place
    pl = place( place )
    raise "Unable to exclude #{pl} from #{self}: One or more transitions" +
      "depend on it" if transitions.any? { |tr| tr.arcs.include? pl }
    return true if @places.delete pl
    return false
  end

  # Excludes a transition from the net. Returns _true_ if successful, _false_ if
  # the transition was not found in the net.
  # 
  def exclude_transition! transition
    tr = transition( transition )
    return true if @transitions.delete tr
    return false
  end

  # Includes an object (either place or transition) in the net. Acts by calling
  # +#include_place!+ or +#include_transition!+, as needed, swallowing errors.
  # 
  def << place_or_transition
    begin
      include_place! place_or_transition
    rescue NameError
      begin
        include_transition! place_or_transition
      rescue NameError
        raise NameError, "Unrecognized place/transition: #{place_or_transition}"
        # TODO: Exceptional Ruby
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

  # Is the net _functional_?
  # 
  def functional?
    transitions.all? { |t| t.functional? }
  end
    
  # Is the net <em>timed</em>?
  # 
  def timed?
    transitions.all? { |t| t.timed? }
  end

  # Creates a new simulation from the net.
  # 
  def new_simulation( **nn )
    YPetri::Simulation.new **nn.merge( net: self )
  end

  # Creates a new timed simulation from the net.
  # 
  def new_timed_simulation( **nn )
    new_simulation( **nn ).aT &:timed?
  end

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
      "#{places.size} places, #{transitions.size} transitions" + ">"
  end

  # Inspect string of the instance.
  # 
  def inspect; to_s end
end # class YPetri::Net
