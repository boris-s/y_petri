#encoding: utf-8

# A mixin for TS transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_TS
    include Type_T
    include Type_S
    
    attr_reader :rate_closure
    
    # Initialization subroutine.
    # 
    def init
      super
      @rate_closure = to_rate_closure
    end
    
    # Transition's rate, given the current system state.
    # 
    def rate
      rate_closure.call
    end
    alias flux rate
    alias propensity rate
    
    # Firing of the transition (rate * Δtime).
    # 
    def firing Δt
      rate * Δt
    end
    
    # Gradient contribution of the transition to all places.
    # 
    def ∇
      codomain >> stoichiometry.map { |coeff| rate * coeff }
    end
    alias gradient_all ∇
    
    # Builds a flux closure.
    # 
    def to_rate_closure
      build_closure
    end
  end # module Type_TS
end # class YPetri::Simulation::TransitionRepresentation
