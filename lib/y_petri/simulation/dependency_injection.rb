#encoding: utf-8

# Place / transition collection mixin for parametrized classes of
# YPetri::Simulation. Expects the module where it is included to define
# +#simulation+ method returning the current simulation instance.
#
class YPetri::Simulation
  module DependencyInjection
    delegate :Place,
             :Transition,
             :MarkingClamp,
             :InitialMarkingObject,
             :Places,
             :Transitions,
             :MarkingClamps,
             :InitialMarking,
             :net,
             :place,
             :transition,
             :element,
             :places,
             :transitions,
             :elements,
             :free_places,
             :clamped_places,
             :f2a,
             :c2a,
             :m_vector,
             to: :simulation
  end # class DependencyInjection
end # class YPetri::Simulation
