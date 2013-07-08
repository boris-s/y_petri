#encoding: utf-8

require_relative 'transition_representation/types'
require_relative 'transition_representation/a'
require_relative 'transition_representation/A'
require_relative 'transition_representation/t'
require_relative 'transition_representation/T'
require_relative 'transition_representation/s'
require_relative 'transition_representation/S'
require_relative 'transition_representation/ts'
require_relative 'transition_representation/Ts'
require_relative 'transition_representation/tS'
require_relative 'transition_representation/TS'
require_relative 'transition_representation/collections'

# Representation of a YPetri::Transition inside a YPetri::Simulation instance.
#
class YPetri::Simulation::TransitionRepresentation
  include Types

  attr_reader :source # source transition
  attr_reader :domain, :codomain
  attr_reader :function # source transition function
    
  # Expect a single YPetri place as an argument.
  # 
  def initialize net_transition
    @source = net.transition( net_transition )
    @domain, @codomain = places( *source.domain ), places( *source.codomain )
    super
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

  # Builds the transition's function into a closure.
  # 
  def build_closure
    mv, f = simulation.m_vector, function
    eval "-> { f.( %s ) }" % domain_access_code( vector: :mv )
  end

  # Builds a code string for accessing the domain directly from a marking
  # vector, given as argument.
  # 
  def domain_access_code( vector: :m_vector )
    Matrix.column_vector_access_code( vector: vector, indices: domain_indices )
  end

  # Builds a code string that assigns to the free places of the codomain.
  # 
  def codomain_assignment_code vector: (fail ArgumentError, "No vector!"),
                               source: (fail ArgumentError, "No source array!")
    Matrix.column_vector_assignment_code( vector: vector,
                                          indices: free_codomain_indices,
                                          source: source )
  end
end # class YPetri::Simulation::TransitionRepresentation
