#encoding: utf-8

# Public command interface of YPetri.
# 
module YPetri
  class Manipulator
    attr_reader :workspace

    def initialize
      @workspace = YPetri::Workspace.new
      super
    end

    require_relative 'manipulator/selection'
    require_relative 'manipulator/hash_key_pointer'
    require_relative 'manipulator/petri_net_related_methods'
    require_relative 'manipulator/simulation_related_methods'

    include YPetri::Manipulator::PetriNetRelatedMethods
    include YPetri::Manipulator::SimulationRelatedMethods
  end # class Manipulator
end # module YPetri
