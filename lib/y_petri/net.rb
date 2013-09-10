# encoding: utf-8

require_relative 'net/element_access'
require_relative 'net/visualization'
require_relative 'net/own_state'
require_relative 'net/data_set'
require_relative 'net/state'

# Represents a _Petri net_: A collection of places and transitions. The
# connector arrows – called _arcs_ in classical Petri net terminology – can be
# considered a property of transitions. Therefore in +YPetri::Net+, you won't
# find arcs as first-class citizens, but only as a synonym denoting nearest
# neighbors of elements (places or transitions).
# 
class YPetri::Net
  ★ NameMagic                        # ★ means include
  ★ ElementAccess                    # to be below ElementAccess
  ★ Visualization
  ★ OwnState

  class << self
    ★ YPetri::World::Dependency

    # Constructs a net containing a particular set of elements.
    # 
    def of elements
      new.tap { |inst| elements.each { |e| inst << e } }
    end

    private :new
  end

  delegate :world, to: "self.class"
  delegate :Place, :Transition, :Net, to: :world

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

  # Includes a place in the receiver. Returns _true_ if successful, _false_ if
  # the place is already included in the receiver net. 
  # 
  def include_place id
    pl = Place().instance( id )
    return false if includes_place? pl
    true.tap { @places << pl }
  end

  # Includes a transition in the receiver. Returns _true_ if successful, _false_
  # if the transition is already included in the net. The arcs of the transition
  # being included may only connect to the places already in the receiver net.
  # 
  def include_transition id
    tr = Transition().instance( id )
    return false if includes_transition? tr
    msg = "Transition #{tr} has arcs to places outside #{self}!"
    fail msg unless tr.arcs.all? { |p| includes_place? p }
    true.tap { @transitions << tr }
  end

  # Excludes a place from the receiver. Returns _true_ if successful, _false_
  # if the place was not found in the receiver net. A place may not be excluded
  # from the receiver so long as any transitions therein connect to it.
  # 
  def exclude_place id
    pl = Place().instance( id )
    msg = "Unable to exclude #{pl} from #{self}: Transition(s) depend on it!"
    fail msg if transitions.any? { |tr| tr.arcs.include? pl }
    false.tap { return true if @places.delete( pl ) }
  end

  # Excludes a transition from the receiver. Returns _true_ if successful,
  # _false_ if the transition was not found in the receiver net.
  # 
  def exclude_transition id
    tr = Transition().instance( id )
    false.tap { return true if @transitions.delete( tr ) }
  end

  # Includes another net in the receiver net. Returns _true_ if successful
  # (ie. if there was any change to the receiver net), _false_ if the receiver
  # net already includes the argument net.
  # 
  def include_net id
    net = Net().instance( id )
    p_rslt = net.pp.map { |p| include_place p }.reduce :|
    t_rslt = net.tt.map { |t| include_transition t }.reduce :|
    p_rslt || t_rslt
  end
  alias merge! include_net

  # Excludes another net from the receiver net. Returns _true_ if successful
  # (ie. if there was any change to the receiver net), _false_ if the receiver
  # net contained no element of the argument net.
  # 
  def exclude_net id
    net = Net().instance( id )
    t_rslt = net.tt.map { |t| exclude_transition t }.reduce :|
    p_rslt = net.pp.map { |p| exclude_place p }.reduce :|
    p_rslt || t_rslt
  end

  # Includes an element in the net.
  # 
  def << element_id
    begin
      element = self.class.place( element_id )
      type = :place
    rescue NameError, TypeError
      begin
        element = self.class.transition( element_id )
        type = :transition
      rescue NameError, TypeError => err
        raise TypeError, "Current world contains no place or transition " +
          "identified by #{element_id}! (#{err})"
      end
    end
    # Separated to minimize the code inside rescue clause:
    if type == :place then include_place element
    elsif type == :transition then include_transition element
    else fail "Implementation error in YPetri::Net#<<!" end
  end

  # Creates a new net that contains all the places and transitions of both
  # operands.
  # 
  def + other
    self.class.new.tap do |net|
      net.merge! self
      net.merge! other
    end
  end

  # Creates a new net that contains the places and transition of the receiver
  # after excluding the second operand.
  # 
  def - other
    self.class.new.tap do |net|
      net.merge! self
      net.exclude_net other
    end
  end

  # Is the net _functional_?
  # 
  def functional?
    transitions.any? { |t| t.functional? }
  end

  # Is the net _timed_?
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
      "#{pp.size rescue '∅'} places, #{tt.size rescue '∅'} transitions" +
      ">"
  end

  # Inspect string of the instance.
  # 
  def inspect
    to_s
  end
end # class YPetri::Net
