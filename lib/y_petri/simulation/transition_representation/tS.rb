#encoding: utf-8

# A mixin for tS transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_tS
    include Type_t
    include Type_S
    
    attr_reader :firing_closure
    
    # Initialization subroutine.
    # 
    def init
      super
      @firing_closure = to_firing_closure
    end
    
    # Transition's firing, given the current system state.
    # 
    def firing
      firing_closure.call
    end
    
    # Change, to all places, as it would happen if the transition fired.
    # 
    def Δ
      codomain >> stoichiometry.map { |coeff| firing * coeff }
    end
    alias delta_all Δ
    
    # Builds a firing closure.
    # 
    def to_firing_closure
      build_closure
    end
  end # module Type_tS
end # class YPetri::Simulation::TransitionRepresentation
