# encoding: utf-8

module YPetri::Simulation::Timeless
  class Core
    # Implicit Euler for timeless nets. Simply, timeless transitions
    # fire simultaneously, after which A transitions (if any) fire.
    #
    module PseudoEuler
      # Name of this method.
      # 
      def method
        :pseudo_euler
      end

      def step!
        increment_marking_vector Δ
        assignment_transitions_all_fire!
        note_state_change
      end
    end
  end
end
