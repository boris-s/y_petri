# encoding: utf-8

# A simulation method class.
# 
class YPetri::Simulation
  class Method
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

    class << self
      alias __new__ new

      def new &block
        Class.new( self ) do
          prepend( Module.new &block )
        end.__new__
      end
    end

    # Makes a single step.
    # 
    def step!
      super
      simulation.recording.note_state_change
    end

    # Delta for free places.
    # 
    def delta_timeless
      delta_ts + delta_tS
    end
    alias delta_t delta_timeless

    # Delta contribution by ts transitions.
    # 
    def delta_ts
      simulation.tS_stoichiometry_matrix * firing_vector_tS
    end

    # Firing vector of tS transitions.
    # 
    def firing_vector_tS
      simulation.tS_delta_closure.call
    end

    # Increments the marking vector by a given delta.
    # 
    def increment_marking_vector( delta )
      simulation.increment_marking_vector_closure.( delta )
    end

    # Fires assignment transitions.
    # 
    def assignment_transitions_all_fire!
      simulation.A_assignment_closure.call
    end
  end
end
