# encoding: utf-8

# A mixin for collections of S transitions.
# 
class YPetri::Simulation::Transitions
  module Type_S
    include Type_a

    # Returns the collection's stoichiometry matrix versus free places.
    # 
    def stoichiometry_matrix
      map( &:sparse_stoichiometry_vector )
        .reduce( Matrix.empty( places.free.size, 0 ), :join_right )
    end

    # Returns the collection's stoichiometry matrix versus all places.
    # 
    def SM
      map( &:sparse_sv )
        .reduce( Matrix.empty( places.size, 0 ), :join_right )
    end
    alias stoichiometry_matrix_all SM
  end # module Type_S
end # class YPetri::Simulation::Transitions
