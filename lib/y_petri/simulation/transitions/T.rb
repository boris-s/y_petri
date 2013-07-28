#encoding: utf-8

# A mixin for collections of T transitions.
# 
class YPetri::Simulation::Transitions
  module Type_T
    include Type_a

    # T transitions have gradient closures.
    # 
    def gradient_closures
      map &:gradient_closure
    end

    # Gradient by the T transitions.
    # 
    def gradient
      Ts().gradient + TS().gradient
    end

    # State change of free places if the timed transitions fire for given time.
    # 
    def delta Δt
      gradient * Δt
    end

    # State change of all places if the timed transitions fire for given time.
    # 
    def Δ Δt
      ∇ * Δt
    end
    alias delta_all Δ
  end # module Type_T
end # class YPetri::Simulation::Transitions
