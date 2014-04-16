#encoding: utf-8

# Representation of a YPetri::Transition inside a YPetri::Simulation instance.
#
class YPetri::Simulation
  class TransitionRepresentation < NodeRepresentation
    require_relative 'transition_representation/types'

    ★ Types

    attr_reader :domain, :codomain
    attr_reader :function # source transition function

    # Expect a single YPetri place as an argument.
    # 
    def initialize net_transition
      super
      @domain, @codomain = Places( source.domain ), Places( source.codomain )
      type_init
    end

    # Returns the indices of this transition's domain in the marking vector.
    # 
    def domain_indices
      domain.map { |p| places.index p }
    end

    # Returns the indices of this transition's codomain in the marking vector.
    # 
    def codomain_indices
      codomain.map { |p| places.index p }
    end

    # Returns the indices of this transition's domain among the free places.
    # 
    def free_domain_indices
      domain.map { |p| free_places.index p }
    end

    # Returns the indices of this transition's codomain among the free places.
    # 
    def free_codomain_indices
      codomain.map { |p| free_places.index p }
    end

    # Builds a code string for accessing the domain directly from a marking
    # vector, given as argument.
    # 
    def domain_access_code( vector: :m_vector )
      Matrix.column_vector_access_code( vector: vector,
                                        indices: domain_indices )
    end

    # Builds a code string that assigns to the free places of the codomain.
    # 
    def codomain_assignment_code vector: (fail ArgumentError, "No vector!"),
                                 source: (fail ArgumentError, "No source array!")
      Matrix.column_vector_assignment_code( vector: vector,
                                            indices: free_codomain_indices,
                                            source: source )
    end

    # Builds a closure that increments a vector with this transition's codomain.
    # 
    def increment_by_codomain_code vector: (fail ArgumentError, "No vector!"),
                                   source: (fail ArgumentError, "No source array!")
      Matrix.column_vector_increment_by_array_code vector: vector,
                                                   indices: free_codomain_indices,
                                                   source: source
    end
  end # class TransitionRepresentation
end # class YPetri::Simulation
