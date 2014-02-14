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

  # Constructor of a place governed by an assignment transition. The transition
  # is named by adding "_ϝ" (digamma, resembles mathematical f used to denote
  # functions) suffix to the place's name. For example,
  #
  # Fred = PAT Joe do |joe| joe * 2 end
  #
  # creates a place named "Fred" and an assignment transition named "Fred_ϝ"
  # that keeps Fred equal to 2 times Joe.
  #
  def PAT *domain, **named_args, &block
    Place().tap do |place|
      transition = AT place, domain: domain, &block
      # Rig the hook to name the transition as soon as the place is named.
      place.name_set_hook do |name| transition.name = "#{name}_ϝ" end
      place.name = named_args.delete :name if named_args.has? :name, syn!: :ɴ
    end
  end
  alias ϝ PAT

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


  # Timed transition constructor: Creates a new timed transition in the current
  # world. Rate can be supplied either as +:rate+ named argument, or as a block.
  # If none is supplied, rate argument defaults to 1.
  # 
  def TT( *ordered, **named, &block )
    if named.has? :rate then
      fail ArgumentError, "Block must not be given if :rate named argument " +
        "is given!" if block
    else
      named.update rate: block || 1 # default rate is 1
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
