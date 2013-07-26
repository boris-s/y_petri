#encoding: utf-8

# Public command interface of YPetri.
# 
module YPetri
  class Agent
    attr_reader :world

    def initialize
      @world = YPetri::World.new
      super
    end

    require_relative 'agent/selection'
    require_relative 'agent/hash_key_pointer'
    require_relative 'agent/petri_net_related'
    require_relative 'agent/simulation_related'

    include self::PetriNetRelated
    include self::SimulationRelated
  end # class Agent
end # module YPetri
