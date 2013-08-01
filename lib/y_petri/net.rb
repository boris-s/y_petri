#encoding: utf-8

require_relative 'net/visualization'
require_relative 'net/element_access'
require_relative 'net/state'

# Represents a _Petri net_: A collection of places and transitions. The
# connector arrows – called _arcs_ in classical Petri net terminology – can be
# considered a property of transitions. Therefore in +YPetri::Net+, you won't
# find arcs as first-class citizens, but only as a synonym denoting nearest
# neighbors of elements (places or transitions).
# 
class YPetri::Net
  include NameMagic
  include YPetri::World::Dependency # it is important for the Dependency
  include ElementAccess             # to be below ElementAccess

  class << self
    include YPetri::World::Dependency

    # Constructs a net containing a particular set of elements.
    # 
    def of *elements
      new.tap { |inst| elements.each { |e| inst << e } }
    end
  end

  delegate :world, to: "self.class"

  # Takes 2 arguments (+:places+ and +:transitions+) and builds a net from them.
  # 
  def initialize( places: [], transitions: [] )
    param_class( { State: State }, with: { net: self } )
    @places, @transitions = [], []
    places.each &method( :include_place )
    transitions.each &method( :include_transition )
    param_class( { Simulation: YPetri::Simulation },
                 with: { net: self } )
  end

  # Includes a place in the net. Returns _true_ if successful, _false_ if the
  # place is already included in the net.
  # 
  def include_place id
    pl = Place().instance( id )
    return false if includes_place? pl
    true.tap { @places << pl }
  end

  # Includes a transition in the net. Returns _true_ if successful, _false_ if
  # the transition is already included in the net. The arcs of the transition
  # being included may only connect to the places already in the net.
  # 
  def include_transition id
    tr = Transition().instance( id )
    return false if includes_transition? tr
    true.tap { @transitions << tr }
  end

  # Excludes a place from the net. Returns _true_ if successful, _false_ if the
  # place was not found in the net. A place may not be excluded from the net so
  # long as any transitions in the net connect to it.
  # 
  def exclude_place id
    pl = Place().instance( id )
    msg = "Unable to exclude #{pl} from #{self}: Transition(s) depend on it!"
    fail msg if transitions.any? { |tr| tr.arcs.include? pl }
    false.tap { return true if @places.delete( pl ) }
  end

  # Excludes a transition from the net. Returns _true_ if successful, _false_ if
  # the transition was not found in the net.
  # 
  def exclude_transition id
    tr = Transition().instance( id )
    false.tap { return true if @transitions.delete( tr ) }
  end

  # Includes an element in the net.
  # 
  def << element_id
    element_type, element = begin
                              [ :place,
                                self.class.place( element_id ) ]
                            rescue NameError, TypeError
                              begin
                                [ :transition,
                                  self.class.transition( element_id ) ]
                              rescue NameError, TypeError => err
                                msg = "Current world contains no place or" +
                                  "transition identified by #{element_id}!"
                                raise TypeError, "#{msg} (#{err})"
                              end
                            end
    case element_type
    when :place then include_place( element )
    when :transition then include_transition( element )
    else fail "Mangled method YPetri::Net#<<!" end
  end

  # Is the net _functional_?
  # 
  def functional?
    transitions.all? { |t| t.functional? }
  end

  # Is the net <em>timed</em>?
  # 
  def timed?
    transitions.any? { |t| t.timed? }
  end

  # Creates a new simulation from the net.
  # 
  def simulation( **settings )
    Simulation().__new__ **settings
  end

  # Networks are equal when their places and transitions are equal.
  # 
  def == other
    return false unless other.class_complies?( self.class )
    places == other.places && transitions == other.transitions
  end

  # Returns a string briefly describing the net.
  # 
  def to_s
    "#<Net: " +
      ( name.nil? ? "%s" : "name: #{name}, %s" ) %
      "#{pp.size rescue '∅'} places, #{tt.size rescue '∅'} transitions" + ">"
  end

  # Inspect string of the instance.
  # 
  def inspect
    to_s
  end
end # class YPetri::Net
