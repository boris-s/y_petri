#encoding: utf-8

# Place / transition collection mixin for parametrized classes of
# YPetri::Simulation. Expects the module where it is included to define
# +#simulation+ method returning the current simulation instance.
#
class YPetri::Simulation
  module Dependency
    delegate :Place,
             :Transition,
             :MarkingClamp,
             :InitialMarkingObject,
             :Places,
             :Transitions,
             :MarkingClamps,
             :InitialMarking,
             :net,
             :p, :t, :e,
             :pp, :tt, :ee,
             :free_pp, :clamped_pp,
             :ts_tt, :tS_tt, :Ts_tt, :TS_tt,
             :t_tt, :T_tt, :s_tt, :S_tt,
             :A_tt,
             :f2a, :c2a,
             :m_vector,
             :recorder,
             to: :simulation

    # Delegates to the protected (and private) methods of simulation.
    # 
    def self.delegate_to_simulation! *symbols
      symbols.each do |sym|
        module_exec do
          define_method sym do |*aa, &b| simulation.send sym, *aa, &b end
        end
      end
    end

    def element *args, &block
      simulation.send :element, *args, &block
    end

    def place *args, &block
      simulation.send :place, *args, &block
    end

    def transition *args, &block
      simulation.send :transition, *args, &block
    end

    def elements *args, &block
      simulation.send :elements, *args, &block
    end

    def places *args, &block
      simulation.send :places, *args, &block
    end

    def transitions *args, &block
      simulation.send :transitions, *args, &block
    end

    def free_places *args, &block
      simulation.send :free_places, *args, &block
    end

    def clamped_places *args, &block
      simulation.send :clamped_places, *args, &block
    end

    def ts_transitions *args, &block
      simulation.send :ts_transitions, *args, &block
    end

    def tS_transitions *args, &block
      simulation.send :tS_transitions, *args, &block
    end

    def Ts_transitions *args, &block
      simulation.send :Ts_transitions, *args, &block
    end

    def TS_transitions *args, &block
      simulation.send :TS_transitions, *args, &block
    end

    def t_transitions *args, &block
      simulation.send :t_transitions, *args, &block
    end

    def T_transitions *args, &block
      simulation.send :T_transitions, *args, &block
    end

    def s_transitions *args, &block
      simulation.send :s_transitions, *args, &block
    end

    def S_transitions *args, &block
      simulation.send :S_transitions, *args, &block
    end

    def A_transitions *args, &block
      simulation.send :A_transitions, *args, &block
    end
  end # class Dependency
end # class YPetri::Simulation
