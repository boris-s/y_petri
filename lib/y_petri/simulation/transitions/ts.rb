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

    # Constructs a delta closure that outputs a delta vector corresponding to
    # free places. The vector is the delta contribution of the transitions in
    # this collection.
    # 
    def to_delta_closure
      free_pl, closures = free_places, delta_closures
      body = map.with_index do |t, i|
        "a = closures[ #{i} ]\n" +
          t.increment_by_codomain_code( vector: "delta", source: "a" )
      end
      λ = <<-LAMBDA
        -> do
        delta = simulation.MarkingVector.zero( free_pl )
        #{body}
        return delta
        end
      LAMBDA
      eval λ
    end
  end
end # class YPetri::Simulation::Transitions
