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

    delegate_to_simulation! :element, :place, :transition,
                            :elements, :places, :transitions,
                            :free_places, :clamped_places,
                            :ts_transitions, :tS_transitions,
                            :Ts_transitions, :TS_transitions,
                            :t_transitions, :T_transitions,
                            :s_transitions, :S_transitions,
                            :A_transitions
  end # class Dependency
end # class YPetri::Simulation
