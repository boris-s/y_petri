# encoding: utf-8

# Public command interface of YPetri.
# 
module YPetri::Agent::PetriNetRelated
  # Net selection class.
  # 
  NetSelection = Class.new YPetri::Agent::Selection

  # Net point
  # 
  attr_reader :net_point

  # Net selection.
  # 
  attr_reader :net_selection

  def initialize
    net_point_reset
    @net_selection = NetSelection.new
    super
  end

  # Elements and selections:
  # 
  delegate :place, :transition, :element,
           :nets, :places, :transitions,
           to: :world

  # Place name.
  # 
  def pl( place_id )
    place( place_id ).name
  end

  # Transition name.
  # 
  def tr( transition_id )
    transition( transition_id ).name
  end

  # Place names.
  # 
  def pn
    places.names
  end

  # Transition names.
  # 
  def tn
    transitions.names
  end

  # Net names.
  # 
  def nn
    nets.names
  end

  # Place constructor: Creates a new place in the current world.
  # 
  def Place( *ordered_args, **named_args, &block )
    fail ArgumentError, "If block is given, :guard named argument " +
      "must not be given!" if named_args.has? :guard if block
    named_args.update( guard: block ) if block # use block as a guard
    named_args.may_have :default_marking, syn!: :m!
    named_args.may_have :marking, syn!: :m
    world.Place.send( :new, *ordered_args, **named_args, &block )
  end

  # Transition constructor: Creates a new transition in the current world.
  # 
  def Transition( *ordered, **named, &block )
    world.Transition.send( :new, *ordered, **named, &block )
  end

  # Timed transition constructor: Creates a new timed transition in the current
  # world. Rate closure has to be supplied as a block.
  # 
  def T( *ordered, **named, &block )
    fail ArgumentError, "Timed transition constructor requires a block " +
      "defining the rate function!" unless block
    world.Transition.send( :new, *ordered, **named.update( rate: block ) )
  end

  # Timed stoichiometric transition constructor, that expects stoichiometry
  # given directly as hash-collected arguments. Two special keys allowed are
  # +:name+ (alias +:ɴ) and +:domain+. (Key +:codomain+ is not allowed.)
  # 
  def TS **stoichiometry, &block
    args = { s: stoichiometry }
    args.update name: stoichiometry.delete( :name ) if
      stoichiometry.has? :name, syn!: :ɴn
    args.update domain: stoichiometry.delete( :domain ) if
      stoichiometry.has? :domain
    T **args, &block
  end

  # Assignment transition constructor: Creates a new assignment transition in
  # the current world. Ordered arguments are collected as codomain. Domain key
  # (+:domain) is optional. Assignment closure must be supplied in a block.
  # 
  def A( *codomain, **nn, &block )
    fail ArgumentError, "Assignment transition constructor requires a block " +
      "defining the assignment function!" unless block
    world.Transition.send( :new,
                           codomain: codomain,
                           assignment: true,
                           action: block,
                           **nn )
  end

  # Net constructor: Creates a new Net instance in the current world.
  # 
  def Net *args, &block
    world.Net.send( :new, *args, &block )
  end

  # Returns the net identified, or the net at point (if no argument given).
  # 
  def net id=nil
    id.nil? ? @net_point : world.net( id )
  end

  # Sets the net point to a given net, or to world.Net::Top if none given.
  # 
  def net_point_reset id=world.Net::Top
    @net_point = world.net( id )
  end

  # Sets net point to a given net.
  # 
  def net_point= id
    net_point_reset id
  end
end # module YPetri::Agent::PetriNetRelated
