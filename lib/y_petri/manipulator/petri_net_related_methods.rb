# -*- coding: utf-8 -*-
# Public command interface of YPetri.
# 
module YPetri::Manipulator::PetriNetRelatedMethods
  # Net selection class.
  # 
  NetSelection = Class.new YPetri::Manipulator::Selection

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
           to: :workspace

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

  # Place constructor: Creates a new place in the current workspace.
  # 
  def Place( *ordered_args, **named_args, &block )
    fail ArgumentError, "If block is given, :guard named argument " +
      "must not be given!" if named_args.has? :guard if block
    named_args.update( guard: block ) if block # use block as a guard
    named_args.may_have :default_marking, syn!: :m!
    named_args.may_have :marking, syn!: :m
    workspace.Place.new *ordered_args, **named_args
  end

  # Transition constructor: Creates a new transition in the current workspace.
  # 
  def Transition( *ordered, **named, &block )
    workspace.Transition.new *ordered, **named, &block
  end

  # Timed transition constructor: Creates a new timed transition in the current
  # workspace. Rate closure has to be supplied as a block.
  # 
  def T( *ordered, **named, &block )
    workspace.Transition.new *ordered, **named.update( rate: block )
  end

  # Assignment transition constructor: Creates a new assignment transition in
  # the current workspace. Assignment closure has to be supplied as a block.
  # 
  def A( *ordered, **named, &block )
    workspace.Transition.new *ordered,
                             **named.update( assignment: true, action: block )
  end

  # Net constructor: Creates a new Net instance in the current workspace.
  # 
  def Net *ordered, **named, &block
    workspace.Net.new *ordered, **named, &block
  end

  # Returns the net identified, or the net at point (if no argument given).
  # 
  def net id=nil
    id.nil? ? @net_point : workspace.net( id )
  end

  # Sets the net point to a given net, or to workspace.Net::Top if none given.
  # 
  def net_point_reset id=workspace.Net::Top
    @net_point = workspace.net( id )
  end

  # Sets net point to a given net.
  # 
  def net_point= id
    net_point_reset id
  end
end # module YPetri::Manipulator::PetriNetRelatedMethods
