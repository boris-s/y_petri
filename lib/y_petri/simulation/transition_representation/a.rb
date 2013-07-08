#encoding: utf-8

# A mixin for non-assignment transition representations.
# 
module YPetri::Simulation::TransitionRepresentation::Type_a
  # Assignment action -- false for non-assignment transitions.
  # 
  def A?
    false
  end
  alias assignment_action? A?
  alias assignment? A?

  # Normal (non-assignment) action -- true for A transitions
  # 
  def a?
    true
  end

  # Initialization subroutine.
  # 
  def init
  end

  # Change, for free places, as it would happen if the transition fired.
  # 
  def delta
    Δ.select { |p, v| p.free? }
  end
end # class YPetri::Simulation::TransitionRepresentation::Type_a
