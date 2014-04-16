# encoding: utf-8

# Implicit Euler for timeless nets.
#
module YPetri::Core::Timeless::PseudoEuler
  # Method #step! for timeless +pseudo_euler+ method. Simply, timeless
  # transitions fire simultaneously, after which, A transitions (if any) fire.
  # 
  def step!
    increment_marking_vector Δ
    assignment_transitions_all_fire!
    alert!
  end
end # module YPetri::Core::Timeless::PseudoEuler
