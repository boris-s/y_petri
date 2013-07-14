#encoding: utf-8

# A mixin for ts transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_ts
    include Type_t
    include Type_s

    attr_reader :delta_closure

    # Initialization subroutine.
    # 
    def init
      super
      @delta_closure = to_delta_closure
    end

    # Delta state closure.
    # 
    def to_delta_closure
      build_closure
    end

    # Change, to all places, as it would happen if the transition fired.
    # 
    def Δ
      codomain >> delta_closure.call
    end
    alias delta_all Δ
  end # module Type_ts
end # class YPetri::Simulation::TransitionRepresentation
