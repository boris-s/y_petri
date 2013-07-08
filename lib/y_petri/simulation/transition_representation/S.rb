#encoding: utf-8

# A mixin for S transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_S
    include Type_a
    
    attr_reader :stoichiometry
    
    # Sparse stoichiometry vector corresponding to the free places.
    # 
    attr_reader :sparse_stoichiometry_vector
    
    # Sparse stoichiometry vector corresponding to all the places.
    # 
    attr_reader :sparse_sv
    
    # True for stoichiometric transitions.
    # 
    def S?
      true
    end
    alias stoichiometric? S?
    
    # False for stoichiometric transitions.
    # 
    def s?
      false
    end
    alias nonstoichiometric? s?
    
    # Initialization subroutine.
    # 
    def init
      super
      @stoichiometry = source.stoichiometry
      @sparse_stoichiometry_vector =
        Matrix.correspondence_matrix( codomain, free_places ) *
        stoichiometry.to_column_vector
      @sparse_sv = Matrix.correspondence_matrix( codomain, places ) *
        stoichiometry.to_column_vector
    end
  end # module Type_S
end # class YPetri::Simulation::TransitionRepresentation
