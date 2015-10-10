# encoding: utf-8

# Mixin providing collections of places / transitions to classes parametrized
# by an instance of +YPetri::Simulation+. Expects the includer classes to
# provide +#simulation+ method returning the +Simulation+ instance with which
# they are parametrized.
# 
class YPetri::Simulation
  module Dependency
    delegate :PlacePS,
             :TransitionPS,
             :MarkingClamp,
             :InitialMarkingObject,
             :PlacesPS,
             :TransitionsPS,
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
    
    # Delegates supplied method symbols to the protected (and private) methods
    # of the simulation.
    # 
    def self.delegate_to_simulation! *method_symbols
      method_symbols.each do |symbol|
        module_exec do
          define_method symbol do |*aa, &b| simulation.send symbol, *aa, &b end
        end
      end
    end

    # Necessary to overcome the protected character of the listed methods.
    # 
    [ :node,
      :place,
      :transition
    ].each { |sym| define_method sym do |e| simulation.send sym, e end }

    # Necessary to overcome the protected character of the listed methods.
    # 
    [ :Nodes,
      :Places,
      :Transitions
    ].each { |sym| define_method sym do |array| simulation.send sym, array end }

    # Necessary to overcome the protected character of the listed methods.
    # 
    [ :nodes,
      :places,
      :free_places,
      :clamped_places,
      :transitions,
      :ts_transitions,
      :tS_transitions,
      :Ts_transitions,
      :TS_transitions,
      :t_transitions,
      :T_transitions,
      :s_transitions,
      :S_transitions,
      :A_transitions
    ].each { |sym| define_method sym do |*e| simulation.send sym, *e end }
  end # class Dependency
end # class YPetri::Simulation
