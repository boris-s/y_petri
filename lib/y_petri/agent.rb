# encoding: utf-8

require_relative 'agent/selection'
require_relative 'agent/hash_key_pointer'
require_relative 'agent/petri_net_aspect'
require_relative 'agent/simulation_aspect'

# A dumb agent that represents and helps the user.
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
