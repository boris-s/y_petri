# Manages the initial marking of a simulation.
#
class YPetri::Simulation
  class InitialMarking < PlaceMapping
    # Sets the initial marking for a given place to a given value.
    # 
    def set( place_id, to: (fail ArgumentError) )
      fail TypeError, "The place #{place_id} is already clamped!" if
        begin # fails if marking clamps are not set yet
          place( place_id ).clamped?
        rescue TypeError, NoMethodError; end
      super
    end
  end # class InitialMarking
end # class YPetri::Simulation
