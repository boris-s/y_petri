#encoding: utf-8

# A mixin for collections of ts transitions.
# 
class YPetri::Simulation::Transitions
  module Type_ts
    include Type_t
    include Type_s

    # delta closure accessor.
    # 
    def delta_closure
      @delta_closure ||= to_delta_closure
    end

    # ts transitions have action closures.
    # 
    def delta_closures
      map &:delta_closure
    end

    # Delta contribution to free places.
    # 
    def delta
      delta_closure.call
    end

    # Delta contribution to all places
    # 
    def Δ
      f2a * delta
    end
    alias delta_all Δ

    # Construcst a delta closure for this collection of transitions.
    # 
    def delta_closure
      zero = simulation.send :zero_m_vector, { places: free_places }
      closures = delta_closures
      code = map.with_index do |t, i|
        "g = closures[#{i}].call\n" +
          t.codomain_assignment_code( vector: :fv, source: :g )
      end.join
      eval "-> { fv = zero\n" + code + "return fv }"
    end
  end
end # class YPetri::Simulation::Transitions
