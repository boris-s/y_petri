# encoding: utf-8

require_relative 'agent/selection'
require_relative 'agent/hash_key_pointer'
require_relative 'agent/petri_net_aspect'
require_relative 'agent/simulation_aspect'

# A dumb agent that represents and helps the user.
#
# An instance of this class (an agent) helps the user to interact
# with the world (YPetri::World instance) and the objects in it
# (Petri net places, transitions, nets etc.). In particular, this
# (YPetri::Agent) class is a convenient place to store various
# "shortcuts" meant to reduce the amount of typing the user has to
# do in order to construct and manipulate the world and its objects
# (such as "pl" instead of "place", "tr" instead of "transition" etc.)
# It would not be a good practice to encumber the classes where these
# methods are implemented with these semi-idiosyncratic shortcuts. This
# way, the implementation of the methods stays the concern of the mother
# classes, and Agent class is responsible for improving the ergonomy
# of their invocation.
# 
class YPetri::Agent
  ★ PetriNetAspect                  # ★ means include
  ★ SimulationAspect

  attr_reader :world

  def initialize
    @world = YPetri::World.new
    super
  end
end # module YPetri::Agent
