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
  # ===========================================================================
  # !!! TODO !!!
  #
  # Refactoring plans for Net class
  #
  # Make it a subclass of Module class, so places and transitions can simply
  # be defined as its constants.
  #
  # ===========================================================================

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
  end

  delegate :world, to: "self.class"
  delegate :Place, :Transition, :Net, to: :world

  # Takes 2 arguments (+:places+ and +:transitions+) and builds a net from them.
  # 
  def initialize( places: [], transitions: [] )
    param_class!( { State: State,
                    Simulation: YPetri::Simulation },
                  with: { net: self } )
    @places, @transitions = [], []
    places.each &method( :include_place )
    transitions.each &method( :include_transition )
  end

  # Includes a place in the receiver. Returns _true_ if successful, _false_ if
  # the place is already included in the receiver net. 
  # 
  def include_place place
    place = Place().instance( place )
    return false if includes_place? place
    true.tap { @places << place }
  end

  # Includes a transition in the receiver. Returns _true_ if successful, _false_
  # if the transition is already included in the net. The arcs of the transition
  # being included may only connect to the places already in the receiver net.
  # 
  def include_transition transition
    transition = Transition().instance( transition )
    return false if includes_transition? transition
    fail "Transition #{transition} has arcs to places outside #{self}!" unless
      transition.arcs.all? { |place| includes_place? place }
    true.tap { @transitions << transition }
  end

  # Excludes a place from the receiver. Returns _true_ if successful, _false_
  # if the place was not found in the receiver net. A place may not be excluded
  # from the receiver so long as any transitions therein connect to it.
  # 
  def exclude_place place
    place = Place().instance( place )
    fail "Unable to exclude #{place} from #{self}: Transitions depend on it!" if
      transitions.any? { |transition| transition.arcs.include? place }
    false.tap { return true if @places.delete( place ) }
  end

  # Excludes a transition from the receiver. Returns _true_ if successful,
  # _false_ if the transition was not found in the receiver net.
  # 
  def exclude_transition transition
    transition = Transition().instance( transition )
    false.tap { return true if @transitions.delete( transition ) }
  end

  # Includes another net in the receiver net. Returns _true_ if successful
  # (ie. if there was any change to the receiver net), _false_ if the receiver
  # net already includes the argument net.
  # 
  def include_net net
    net = Net().instance( net )
    p_results = net.pp.map &method( :include_place )
    t_results = net.tt.map &method( :include_transition )
    ( p_results + t_results ).reduce :|
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

  # Includes an element (place or transition) in the net.
  # 
  def << element
    begin
      type = :place
      place = self.class.place element
    rescue NameError, TypeError
      begin
        type = :transition
        transition = self.class.transition element
      rescue NameError, TypeError => err
        raise TypeError, "Current world contains no place or " +
          "transition #{element}! (#{err})"
      end
    end
    case type # Factored out to minimize the code inside the rescue clause.
    when :place then include_place( place )
    when :transition then include_transition( transition )
    else fail "Implementation error!" end
    return self # important to enable chaining, eg. foo_net << p1 << p2 << t1
  end

  # Creates a new net that contains all the places and transitions of both
  # operands.
  # 
  def + other
    self.class.send( :new ).tap do |net|
      net.merge! self
      net.merge! other
    end
  end

  # Returns a new net that is the result of subtraction of the net given as
  # argument from this net.
  # 
  def - other
    self.class.send( :new ).tap do |net|
      net.include_net self
      net.exclude_net other
    end
  end

  # Is the net _functional_?
  # 
  def functional?
    transitions.any? &:functional?
  end

  # Is the net _timed_?
  # 
  def timed?
    transitions.any? &:timed?
  end

  # Creates a new simulation from the net.
  # 
  def simulation( **settings )
    Simulation().__new__ **settings
  end
  alias new_simulation simulation

  # Networks are equal when their places and transitions are equal.
  # 
  def == other
    return false unless other.class_complies?( self.class )
    places == other.places && transitions == other.transitions
  end

  # Returns a string briefly describing the net.
  # 
  def to_s
    form = "#<Net: %s>"
    content = ( name.nil? ? "%s" : "name: #{name}, %s" ) %
      "#{pp.size rescue '∅'} places, #{tt.size rescue '∅'} transitions"
    form % content
  end

  # Inspect string of the instance.
  # 
  def inspect
    to_s
  end
end # class YPetri::Net
