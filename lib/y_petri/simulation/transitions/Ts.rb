#encoding: utf-8

# A mixin for collections of Ts transitions.
# 
class YPetri::Simulation::Transitions
  module Type_Ts
    include Type_T
    include Type_s

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

    # Constructs a gradient closure that outputs a gradient vector corresponding
    # to free places. The vector is the gradient contribution of the transitions
    # in this collection.
    # 
    def to_gradient_closure
      fp = free_places
      closures = gradient_closures
      sMV = simulation.MarkingVector
      stu = simulation.time_unit

      code_sections = map.with_index do |t, i|
        "a = closures[ #{i} ].call\n" +
          t.increment_by_codomain_code( vector: "g", source: "a" )
      end
      body = code_sections.join( "\n" )
      λ = <<-LAMBDA
        -> do
        g = sMV.zero( fp ) / stu
        #{body}
        return g
        end
      LAMBDA
      eval λ
    end
    alias gradient_closure to_gradient_closure
  end # module Type_Ts
end # class YPetri::Simulation::Transitions
