#encoding: utf-8

# A mixin for collections of tS transitions.
# 
class YPetri::Simulation::Transitions
  module Type_tS
    include Type_t
    include Type_S

    # firing closure accessor.
    # 
    def firing_closure
      @firing_closure ||= to_firing_closure
    end

    # tS transitions have firing closures.
    # 
    def firing_closures
      map &:firing_closure
    end
    
    # Firing vector (to be multiplied by the stoichiometry to get deltas)
    # 
    def firing_vector
      firing_closure.call
    end

    # Delta contribution to free places.
    # 
    def delta
      stoichiometry_matrix * firing_vector
    end

    # Delta contribution to all places
    # 
    def Δ
      SM() * firing_vector
    end
    alias delta_all Δ

    # Builds the firing vector closure, that outputs the firing vector based on
    # the system state when called.
    # 
    def to_firing_closure
      closures = firing_closures
      -> { closures.map( &:call ).to_column_vector }
    end
  end # module Type_tS
end # class YPetri::Simulation::Transitions
