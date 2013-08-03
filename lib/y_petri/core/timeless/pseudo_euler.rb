# encoding: utf-8

# Implicit Euler for timeless nets. Simply, timeless transitions
# fire simultaneously, after which A transitions (if any) fire.
#
module YPetri::Core::Timeless::PseudoEuler
  # Name of this method.
  # 
  def simulation_method
    :pseudo_euler
  end

  def step!
    increment_marking_vector Δ
    assignment_transitions_all_fire!
    alert
  end
end # module YPetri::Core::Timeless::PseudoEuler
