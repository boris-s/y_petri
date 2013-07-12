# encoding: utf-8

module YPetri::Simulation::Timeless
  class Method
    # Timeless transitions fire simultaneously, after which A transitions fire.
    #
    module Regular
      def step!
        increment_marking_vector Δ
        assignment_transitions_all_fire!
      end
    end
  end
end
