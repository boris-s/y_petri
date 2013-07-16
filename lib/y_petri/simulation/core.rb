# encoding: utf-8

# A simulation method class.
# 
class YPetri::Simulation
  class Core
    DEFAULT_METHOD = :pseudo_euler

    module Guarded
      # Guarded simulation.
      # 
      def guarded?
        true
      end

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
      alias __new__ new

      def new( method: nil, guarded: false )
        meth = method || DEFAULT_METHOD
        method_module = const_get( meth.to_s.camelize )
        # TODO: "guarded" argument not handled yet
        Class.new self do prepend method_module end.__new__
      end
    end

    # Simlation is not guarded by default.
    # 
    def guarded?
      false
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
  end # class Core
end # module YPetri::Simulation::Timed
