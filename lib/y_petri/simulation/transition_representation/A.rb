#encoding: utf-8

# A mixin for A transition representations.
# 
module YPetri::Simulation::TransitionRepresentation::Type_A
  attr_reader :assignment_closure, :direct_assignment_closure

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

  # Nil for assignment transitions. Though technically timeless, assignment
  # transitions are considered outside the t/T types.
  # 
  def T?
    nil
  end
  alias timed? T?

  # Nil for assignment transitions. Though technically timeless, assignment
  # transitions are considered outside the t/T types.
  # 
  def t?
    nil
  end
  alias timeless? t?

  # Nil for assignment transitions. Though technically timeless, assignment
  # transitions are considered outside the s/S types.
  # 
  def S?
    nil
  end
  alias timed? T?

  # Nil for assignment transitions. Though technically timeless, assignment
  # transitions are considered outside the s/S types.
  # 
  def s?
    nil
  end
  alias timeless? t?

  # Initialization subroutine.
  # 
  def init
    @function = source.action_closure
    @direct_assignment_closure = construct_direct_assignment_closure
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
    codomain >> Array( function.( *domain.marking ) )
  end

  # Builds an assignment closure, which, when called, directly affects the
  # simulation's marking vector (free places only).
  # 
  def construct_direct_assignment_closure
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

  # Builds an assignment closure, which is bound to the domain and upon calling,
  # returns the assignment action given the current domain marking.
  # 
  def to_assignment_closure
    build_closure
  end

  # Builds the A transition's function (asssignment action closure) into a
  # closure already bound to the domain. Functions for A transitions have
  # return value arity equal to the codomain size. The returned closure here
  # ensures that the return value is always of Array type.
  # 
  def build_closure
    mv, f = simulation.m_vector, function
    λ = "-> { Array f.( %s ) }" % domain_access_code( vector: :mv )
    eval λ
  end
end # class YPetri::Simulation::TransitionRepresentation::Type_A
