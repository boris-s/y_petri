# Collection of marking clamps for YPetri::Simulation.
#
class YPetri::Simulation
  class MarkingClamps < PlaceMapping
    alias clamp_of of

    # Sets the clamp for a given place to a given value.
    # 
    def set place_id, to: (fail ArgumentError, "No :to value!")
      pl = place( place_id )
      # free places change into clamped ones.
      initial_marking.delete pl if begin # fails if initial marking not set yet
                                     pl.free?
                                   rescue TypeError, NoMethodError; end
      super
    end
  end # class MarkingClamps
end # class YPetri::Simulation
