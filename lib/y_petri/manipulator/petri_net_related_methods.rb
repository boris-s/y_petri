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
  def Place *args, &b; workspace.Place.new *args, &b end

  # Transiton constructor: Creates a new transition in the current workspace.
  # 
  def Transition *args, &b; workspace.Transition.new *args, &b end

  # Net constructor: Creates a new Net instance in the current workspace.
  # 
  def Net *args, &b; workspace.Net.new *args, &b end

  # Returns the net identified, or the net at point (if no argument given).
  # 
  def net id=nil; id.nil? ? @net_point : workspace.net( id ) end

  # Returns the name of the identified net, or of the net at point (if no
  # argument given).
  # 
  def ne id=nil; net( id ).name end

  # Sets net point to workspace.Net::Top
  # 
  def net_point_reset; net_point_set( workspace.Net::Top ) end

  # Sets net point to the net identified by the argument (by name or instance).
  # 
  def net_point_set id; @net_point = workspace.net( id ) end
end # module YPetri::Manipulator::PetriNetRelatedMethods
