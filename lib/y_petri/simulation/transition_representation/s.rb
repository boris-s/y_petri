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

    # Builds the s transition's function into a closure. Functions for s
    # transitions (nonstoichiometric transitions) have return value arity
    # equal to the codomain size. The returned closure here ensures that
    # the return value is always of Array type.
    # 
    def build_closure
      mv, f = simulation.m_vector, function
      λ = "-> { Array f.( %s ) }" % domain_access_code( vector: :mv )
      eval λ
    end
  end # module Type_s
end # class YPetri::Simulation::TransitionRepresentation
