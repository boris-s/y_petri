# encoding: utf-8

# A mixin for Ts transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_Ts
    include Type_T
    include Type_s
    
    attr_reader :gradient_closure
    
    # Initialization subroutine.
    # 
    def init
      super
      @gradient_closure = to_gradient_closure
    end
    
    # Gradient contribution of the transition to all places.
    # 
    def ∇
      codomain >> gradient_closure.call
    end
    alias gradient_all ∇
    
    # Builds a gradient closure.
    # 
    def to_gradient_closure
      build_closure
    end
  end # Type_Ts
end # class YPetri::Simulation::TransitionRepresentation
