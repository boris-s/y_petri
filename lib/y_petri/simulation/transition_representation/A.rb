#encoding: utf-8

# A mixin for A transition representations.
# 
module YPetri::Simulation::TransitionRepresentation::Type_A
  attr_reader :assignment_closure
  
  # Assignment action -- true for A transitions.
  # 
  def A?
    true
  end
  alias assignment_action? A?
  alias assignment? A?

  # Normal (non-assignment) action -- false for A transitions
  # 
  def a?
    false
  end

  # Initialization subroutine.
  # 
  def init
    @assignment_closure = to_assignment_closure
  end
  
  # Returns the assignments, as they would happen if this A transition fired,
  # as hash places >> action.
  # 
  def action
    act.select { |pl, v| pl.free? }
  end
  
  # Returns the assignments to all places, as they would happen if A transition
  # could change their values.
  # 
  def act
    codomain >> Array( function.( *domain_marking ) )
  end
  
  # Builds an assignment closure, which, when called, directly affects the
  # simulation's marking vector (free places only).
  # 
  def to_assignment_closure
    mv, ac = simulation.m_vector, source.action_closure
    λ = if codomain.size == 1 then
          target = codomain.first
          return proc {} if target.clamped?
          i = target.m_vector_index
          "-> do mv.send :[]=, #{i}, 0, *ac.( %s ) end"
        else
          assignment_code = codomain_assignment_code vector: :mv, source: :act
          "-> do act = ac.( %s )\n#{assignment_code} end"
        end
    eval λ % domain_access_code( vector: :mv )
  end
end # class YPetri::Simulation::TransitionRepresentation::Type_A
