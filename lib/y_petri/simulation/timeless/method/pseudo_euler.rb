# encoding: utf-8

module YPetri::Simulation::Timeless
  class Method
    # Implicit Euler for timeless nets. Simply, timeless transitions fire simultaneously, after which A transitions (if any) fire.
    #
    module PseudoEuler
      def step!
        increment_marking_vector Δ
        assignment_transitions_all_fire!
      end
    end
  end
end
