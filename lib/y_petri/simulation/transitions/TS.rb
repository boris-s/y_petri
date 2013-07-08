#encoding: utf-8

# Mixin for collections of TS transitions.
#
class YPetri::Simulation::Transitions
  module Type_TS
    include Type_T
    include Type_S

    # Rate vector closure accessor.
    # 
    def rate_closure
      @rate_closure ||= to_rate_closure
    end

    # Rate (flux, propensity) closures.
    # 
    def rate_closures
      map &:rate_closure
    end

    # Rate (flux/propensity) vector.
    # 
    def rate_vector
      to_rate_closure.call
    end
    alias flux_vector rate_vector
    alias propensity_vector rate_vector

    # Firing vector (rate vector * Δtime).
    # 
    def firing_vector Δt
      rate_vector * Δt
    end

    # Gradient contribution to free places.
    # 
    def gradient
      stoichiometry_matrix * rate_vector
    end

    # Gradient contribution to all places.
    # 
    def ∇
      SM() * rate_vector
    end
    alias gradient_all ∇

    # Builds the rate vector closure, that outputs the rate vector based on
    # the system state when called.
    # 
    def to_rate_closure
      rc = rate_closures
      -> { rc.map( &:call ).to_column_vector }
    end
  end # module Type_TS
end # class YPetri::Simulation::Transitions
