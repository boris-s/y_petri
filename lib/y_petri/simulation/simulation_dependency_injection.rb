#encoding: utf-8

# Place / transition collection mixin for parametrized classes of
# YPetri::Simulation. Expects the module where it is included to define
# +#simulation+ method returning the current simulation instance.
#
class YPetri::Simulation
  module SimulationDependencyInjection
    delegate :Place, :Transition, :MarkingClamp, :InitialMarkingObject,
             :Places, :Transitions, :MarkingClamps, :InitialMarking,
             to: :simulation

    # PlaceRepresentation instance identification.
    # 
    def place id
      Place().instance( id )
    end

    # TransitionRepresentation instance identifiaction.
    # 
    def transition id
      Transition().instance( id )
    end
  end # class SimulationDependencyInjection
end # class YPetri::Simulation
