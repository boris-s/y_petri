#encoding: utf-8

require_relative 'net/visualization'
require_relative 'net/selections'
require_relative 'net/state'

# Represents a _Petri net_: A collection of places and transitions. The
# connector arrows – called _arcs_ in classical Petri net terminology – can be
# considered a property of transitions. Therefore in +YPetri::Net+, you won't
# find arcs as first-class citizens, but only as a synonym denoting nearest
# neighbors of elements (places or transitions).
# 
class YPetri::Net
  include NameMagic
  include YPetri::World::Dependency

  class << self
    # Constructs a net containing a particular set of elements.
    # 
    def of *elements
      new.tap { |inst| elements.each { |e| inst << e } }
    end
  end

  attr_reader :places, :transitions

  # Takes 2 arguments (+:places+ and +:transitions+) and builds a net from them.
  # 
  def initialize( places: [], transitions: [] )
    param_class( { State: State }, with: { net: self } )
    @places, @transitions = [], []
    places.each &method( :include_place! )
    transitions.each &method( :include_transition! )
  end

  # Includes a place in the net. Returns _true_ if successful, _false_ if the
  # place is already included in the net.
  # 
  def include_place! place
    pl = place( place )
    return false if includes_place? pl
    true.tap { @places << pl }
  end

  # Includes a transition in the net. Returns _true_ if successful, _false_ if
  # the transition is already included in the net. The arcs of the transition
  # being included may only connect to the places already in the net.
  # 
  def include_transition! transition
    tr = transition( transition )
    return false if includes_transition? tr
    true.tap { @transitions << tr }
  end

  # Excludes a place from the net. Returns _true_ if successful, _false_ if the
  # place was not found in the net. A place may not be excluded from the net so
  # long as any transitions in the net connect to it.
  # 
  def exclude_place! place
    pl = place( place )
    msg = "Unable to exclude #{pl} from #{self}: Transition(s) depend on it!"
    fail msg if transitions.any? { |tr| tr.arcs.include? pl }
    false.tap { return true if @places.delete( pl ) }
  end

  # Excludes a transition from the net. Returns _true_ if successful, _false_ if
  # the transition was not found in the net.
  # 
  def exclude_transition! transition
    tr = transition( transition )
    false.tap { return true if @transitions.delete( tr ) }
  end

  # Includes an element in the net.
  # 
  def << element
    self.tap { begin
                 include_place! element
               rescue NameError, TypeError
                 begin
                   include_transition! element
                 rescue NameError, TypeError => err
                   msg = "Unrecognized place or transition: #{element} (#{err})"
                   raise TypeError, err
                 end
               end }
  end

  # Does the net include a place?
  # 
  def includes_place? id
    pl = begin; place( id ); rescue NameError; nil end
    if pl then places.include? pl else false end
  end
  alias include_place? includes_place?

  # Does the net include a transition?
  # 
  def includes_transition? id
    tr = begin; transition( id ); rescue NameError; nil end
    if tr then transitions.include? tr else false end
  end
  alias include_transition? includes_transition?

  # Inquirer whether the net includes an element.
  # 
  def include? id
    include_place?( id ) || include_transition?( id )
  end
  alias includes? include?

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
  def simulation( **nn )
    YPetri::Simulation.new **nn.merge( net: self )
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
    "#<Net: " + ( name.nil? ? "%s" : "name: #{name}, %s" ) %
      "#{places.size} places, #{transitions.size} transitions" + ">"
  end

  # Inspect string of the instance.
  # 
  def inspect
    to_s
  end
end # class YPetri::Net
