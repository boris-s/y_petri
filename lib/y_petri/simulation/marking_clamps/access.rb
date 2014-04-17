# encoding: utf-8

# Simulation mixin providing access to the marking clamps.
#
class YPetri::Simulation::MarkingClamps
  module Access
    # Expects a single array of clamped places or place ids, and returns an array
    # of their clamp values.
    # 
    def Marking_clamps array
      Clamped_places( array ).map { |place| marking_clamps.fetch( place ) }
    end
    alias marking_Clamps Marking_clamps

    # Expects an arbitrary number of arguments identifying clamped places, whose
    # marking clamps are then returned. If no arguments are given, acts as a
    # getter of +@marking_clamps+ instance variable.
    # 
    def marking_clamps *clamped_places
      return Marking_clamps( clamped_places ) unless clamped_places.empty?
      @marking_clamps or
        fail TypeError, "+@marking_clamps+ not instantiated yet!"
    end
    alias clamps marking_clamps

    # Identification of a single marking clamp. Expects a single clamped place or
    # place id and returns the value of its clamp.
    # 
    def marking_clamp( clamped_place )
      marking_clamps( clamped_place ).first
    end

    # Sets the marking clamp of a place (frontend of +InitialMarking#set+).
    # 
    def set_marking_clamp( place, to: (fail ArgumentError) )
      marking_clamps.set( place, to: to )
    end
  end # module Access
end # class YPetri::Simulation::MarkingClamps
