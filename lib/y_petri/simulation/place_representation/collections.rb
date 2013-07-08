#encoding: utf-8

# Mixin providing collection of places to the Simulation class.
#
class YPetri::Simulation::PlaceRepresentation
  module Collections
    # Without arguments, returns all the places. If arguments are given, they are
    # converted to places before being returned.
    # 
    def places *ids
      return @places if ids.empty?
      Places().load( ids.map { |id| place( id ) } )
    end
    
    # Places' names. Arguments, if any, are treated as in +#places+ method.
    # 
    def pn *ids
      places( *ids ).names
    end
    
    # Free places. If arguments are given, they must be identify free places,
    # and are converted to them.
    # 
    def free_places *ids
      return places.free if ids.empty?
      places.free.subset( ids )
    end
    
    # Clamped places. If arguments are given, they must be identify clamped
    # places, and are converted to them.
    # 
    def clamped_places *ids
      return places.clamped if ids.empty?
      places.clamped.subset( ids )
    end
    
    # Names of free places. Arguments are handled as with +#free_places+.
    # 
    def names_of_free *ids
      free_places( *ids ).names
    end
    alias n_free names_of_free
    
    # Names of free places. Arguments are handled as with +#clamped_places+.
    # 
    def names_of_clamped *ids
      clamped_places( *ids ).names
    end
    alias n_clamped names_of_clamped
  end # module Collections
end # class YPetri::Simulationend::PlaceRepresentation

