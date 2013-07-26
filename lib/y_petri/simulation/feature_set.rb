# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  # Represents a set of features of a simulation state.
  # 
  class FeatureSet
    include DependencyInjection

    attr_reader :marking, :firing, :delta

    # Initializes the feature set.
    # 
    def initialize marking: [], firing: [],
                   delta: { places: [], transitions: [] }
      @marking = x

      @firing = 
      @marking, @firing, @delta = marking, firing, delta
    end
  end # class FeatureSet
end # YPetri::Simulation
