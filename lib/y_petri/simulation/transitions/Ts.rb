#encoding: utf-8

# A mixin for collections of Ts transitions.
# 
class YPetri::Simulation::Transitions
  module Type_Ts
    include Type_T
    include Type_s

    # gradient closure accessor.
    # 
    def gradient_closure
      @gradient_closure ||= to_gradient_closure
    end

    # Member gradient closures.
    # 
    def gradient_closures
      map &:gradient_closure
    end

    # Gradient contribution for free places.
    # 
    def gradient
      gradient_closure.call
    end

    # Gradient contribution to all places.
    # 
    def ∇
      f2a * gradient
    end
    alias gradient_all ∇

    # Constructs a gradient closure that outputs a a gradient vector
    # corresponding to free places. The vector is the gradient contribution
    # of the transitions in this collection.
    # 
    def to_gradient_closure
      zero = simulation.send :zero_∇, { places: free_places }
      closures = gradient_closures
      code = map.with_index do |t, i|
        "g = closures[#{i}].call\n" +
          t.codomain_assignment_code( vector: :fv, source: :g )
      end.join
      eval "-> { fv = zero\n" + code + "return fv }"
    end
  end # module Type_Ts
end # class YPetri::Simulation::Transitions
