# encoding: utf-8

# A mixin for collections of t transitions.
# 
class YPetri::Simulation::Transitions
  module Type_t
    include Type_a

    # State change if the timeless transitions fire once.
    # 
    def delta
      ts.delta + tS.delta
    end

    # State change if the timeless transitions fire once.
    # 
    def Δ
      tS.Δ + ts.Δ
    end
    alias delta_all delta
  end # module Type_T
end # class YPetri::Simulation::Transitions
