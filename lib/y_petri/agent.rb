# encoding: utf-8

require_relative 'agent/selection'
require_relative 'agent/hash_key_pointer'
require_relative 'agent/petri_net_related'
require_relative 'agent/simulation_related'

# Public command interface of YPetri.
# 
class YPetri::Agent
  ★ PetriNetRelated                  # ★ means include
  ★ SimulationRelated

  attr_reader :world

  def initialize
    @world = YPetri::World.new
    super
  end
end # module YPetri::Agent
