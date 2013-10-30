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
  def TT( *ordered, **named, &block )
    if named.has? :rate then
      fail ArgumentError, "Block must not be given if :rate named argument " +
        "is given!" if block
    else
      fail ArgumentError, "Timed transition constructor requires either " +
        "a :rate argument, or a block!" unless block
      named.update rate: block
    end
    world.Transition.send( :new, *ordered, **named )
  end

  # Timed stoichiometric transition constructor, that expects stoichiometry
  # given directly as hash-collected arguments. Two special keys allowed are
  # +:name+ (alias +:ɴ) and +:domain+. (Key +:codomain+ is not allowed.)
  # 
  def TS *domain, **stoichiometry, &block
    nn = stoichiometry
    args = { s: nn }
    args.update name: nn.delete( :name ) if nn.has? :name, syn!: :ɴ
    if domain.empty? then
      args.update domain: nn.delete( :domain ) if nn.has? :domain
    else
      fail ArgumentError, "There must not be any ordered arguments if " +
        "named argument :domain is given!" if nn.has? :domain
      args.update domain: domain
    end
    args.update rate: nn.delete( :rate ) if nn.has? :rate, syn!: :rate_closure
    TT **args, &block
  end

  # Assignment transition constructor: Creates a new assignment transition in
  # the current world. Ordered arguments are collected as codomain. Domain key
  # (+:domain) is optional. Assignment closure must be supplied in a block.
  # 
  def AT( *codomain, **nn, &block )
    fail ArgumentError, "Assignment transition constructor requires a block " +
      "defining the assignment function!" unless block
    world.Transition.send( :new,
                           codomain: codomain,
                           assignment: block,
                           **nn )
  end

  # Net constructor: Creates a new Net instance in the current world.
  # 
  def Net *ordered, of: nil, **named, &block
    if of.nil? then
      world.Net.send( :new, *ordered, **named, &block )
    else
      world.Net.of( of, *ordered, **named, &block )
    end
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
