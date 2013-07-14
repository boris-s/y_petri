# encoding: utf-8

# A simulation method class.
# 
class YPetri::Simulation
  class Method
    DEFAULT = :pseudo_euler

    module Guarded
      # Guarded version of the method.
      # 
      def increment_marking_vector( delta )
        try "to update marking" do
          super( note( "Δ state if tS transitions fire once",
                       is: Δ_if_tS_fire_once ) +
                 note( "Δ state if tsa transitions fire once",
                       is: Δ_if_tsa_fire_once ) )
        end
      end

      # Guarded version of the method.
      # 
      def A_all_fire!
        try "to fire the assignment transitions" do
          super
        end
      end
    end

    include DependencyInjection

    delegate :note_state_change, to: :recording

    class << self
      def construct_core( method_symbol )
        method_module = const_get method_symbol.to_s.camelize
        parametrized_subclass = Class.new self do prepend method_module end
        parametrized_subclass.new
      end
    end

    # Delta for free places.
    # 
    def delta_timeless
      delta_ts + delta_tS
    end
    alias delta_t delta_timeless

    # Delta contribution by tS transitions.
    # 
    def delta_tS
      simulation.tS_stoichiometry_matrix * firing_vector_tS
    end

    # Delta contribution by ts transitions.
    # 
    def delta_ts
      simulation.ts_delta_closure.call
    end

    # Firing vector of tS transitions.
    # 
    def firing_vector_tS
      simulation.tS_firing_closure.call
    end

    # Increments the marking vector by a given delta.
    # 
    def increment_marking_vector( delta )
      print '.'
      simulation.increment_marking_vector_closure.( delta )
    end

    # Fires assignment transitions.
    # 
    def assignment_transitions_all_fire!
      simulation.A_assignment_closure.call
    end
  end
end
