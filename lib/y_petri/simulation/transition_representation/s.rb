#encoding: utf-8

# A mixin for s (nonstoichiometric) transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_s
    include Type_a
    
    # False for non-stoichiometric transitions.
    # 
    def S?
      false
    end
    alias stoichiometric? S?
    
    # True for stoichiometric transitions.
    # 
    def s?
      true
    end
    alias nonstoichiometric? s?
    
    # Initialization subroutine.
    # 
    def init
      super
    end
  end # module Type_s
end # class YPetri::Simulation::TransitionRepresentation
