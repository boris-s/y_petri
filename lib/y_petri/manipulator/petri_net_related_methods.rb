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

  delegate :place, :transition, :pl, :tr,
           :places, :transitions, :nets,
           :pp, :tt, :nn, to: :workspace

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

  # Transiton constructor: Creates a new transition in the current workspace.
  # 
  def Transition( *aa, **oo, &b )
    workspace.Transition.new *aa, **oo, &b
  end

  # Net constructor: Creates a new Net instance in the current workspace.
  # 
  def Net *aa, **oo, &b
    workspace.Net.new *aa, **oo, &b
  end

  # Returns the net identified, or the net at point (if no argument given).
  # 
  def net id=nil
    id.nil? ? @net_point : workspace.net( id )
  end

  # Returns the name of the identified net, or of the net at point (if no
  # argument given).
  # 
  def ne id=nil
    net( id ).name
  end

  # Sets net point to workspace.Net::Top
  # 
  def net_point_reset
    net_point_set( workspace.Net::Top )
  end

  # Sets net point to the net identified by the argument (by name or instance).
  # 
  def net_point_set id
    @net_point = workspace.net( id )
  end
end # module YPetri::Manipulator::PetriNetRelatedMethods
