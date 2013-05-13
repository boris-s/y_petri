# -*- coding: utf-8 -*-

# Workspace instance methods related to Petri net itsef (places, transitions,
# net instances).
# 
module YPetri::Workspace::PetriNetRelatedMethods
  # Readers for @Place, @Transition, @Net instance variables, which should
  # contain said classes, or their instance-specific subclasses.

  # Parametrized Place class.
  # 
  attr_reader :Place

  # Parametrized Transition class.
  # 
  attr_reader :Transition

  # Parametrized Net class.
  # 
  attr_reader :Net

  # Instance initialization.
  # 
  def initialize
    set_up_Top_net # Sets up :Top net encompassing all places and transitions.
    super
  end

  # Returns a place instance identified by the argument.
  # 
  def place which; Place().instance which end

  # Returns a transition instance identified by the argument.
  # 
  def transition which; Transition().instance which end

  # Returns a net instance identified by the argument.
  # 
  def net which; Net().instance which end

  # Returns the name of a place identified by the argument.
  # 
  def pl which; place( which ).name end

  # Returns the name of a transition identified by the argument.
  # 
  def tr which; transition( which ).name end

  # Returns the name of a net identified by the argument.
  # 
  def ne which; net( which ).name end

  # Place instances.
  # 
  def places; Place().instances end

  # Transition instances.
  # 
  def transitions; Transition().instances end

  # Net instances.
  # 
  def nets; Net().instances end

  # Place names.
  # 
  def pp; places.map &:name end

  # Transition names.
  # 
  def tt; transitions.map &:name end

  # Net names.
  # 
  def nn; nets.map &:name end

  private

  # Creates all-encompassing Net instance named :Top.
  # 
  def set_up_Top_net
    Net().new name: :Top # all-encompassing :Top net
    # Hook new places to add themselves magically to the :Top net.
    Place().new_instance_closure { |new_inst| net( :Top ) << new_inst }
    # Hook new transitions to add themselves magically to the :Top net.
    Transition().new_instance_closure { |new_inst| net( :Top ) << new_inst }    
  end
end # module YPetri::Workspace::PetriNetRelatedMethods
