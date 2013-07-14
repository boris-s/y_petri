#encoding: utf-8

# Simulation mixin providing access to the marking clamps.
#
class YPetri::Simulation::MarkingClamps
  module Access
    # Without arguments, acts as a getter of the @marking_clamp hash. If
    # arguments are supplied, they must identify clamped places, and are mapped
    # to their clamp values.
    # 
    def marking_clamps ids=nil
      if ids.nil? then
        @marking_clamps or
          fail TypeError, "MarkingClamps object not instantiated yet!"
      else
        clamped_places( ids ).map { |p| marking_clamp of: p }
      end
    end
    alias clamps marking_clamps

    # Marking clamp identification.
    # 
    def marking_clamp( of: (fail ArgumentError) )
      marking_clamps.clamp_of( of )
    end

    # Sets the marking clamp of a place (frontend of +InitialMarking#set+).
    # 
    def set_marking_clamp( of: (fail ArgumentError), to: (fail ArgumentError) )
      marking_clamps.set( of, to: to )
    end
  end # module Access
end # class YPetri::Simulation::MarkingClamps

