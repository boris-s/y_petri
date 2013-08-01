#encoding: utf-8

# Simulation mixin providing access to places.
#
class YPetri::Simulation::Places
  module Access
    # With no arguments, a reader of @f2a -- the correspondence matrix between
    # free places and all places. If argument is given, it is assumed to be
    # a column vector, and multiplication is performed.
    # 
    def f2a arg=nil
      if arg.nil? then @f2a else @f2a * arg end
    end

    # With no arguments, a reader of @c2a -- the correspondence matrix between
    # clamped places and all places. If argument is given, it is assumed to be
    # a column vector, and multiplication is performed.
    # 
    def c2a arg=nil
      if arg.nil? then @c2a else @c2a * arg end
    end

    # Does a place belong to the simulation?
    # 
    def includes_place? id
      true.tap { begin; place id
                 rescue NameError, TypeError
                   return false
                 end }
    end
    alias include_place? includes_place?

    # Place of the simulation (belonging to the net).
    # 
    def p( id )
      place( id ).source
    end

    # Places of the simulation (belonging to the net).
    # 
    def pp( ids=nil )
      places( ids ).sources
    end

    # Free places of the simulation (belonging to the net).
    # 
    def free_pp( ids=nil )
      free_places( ids ).sources
    end

    # Clamped places of the simulation (belonging to the net).
    # 
    def clamped_pp( ids=nil )
      clamped_places( ids ).sources
    end

    # Places' names. Arguments, if any, are treated as in +#places+ method.
    # 
    def pn( ids=nil )
      places( ids ).names
    end

    # Names of free places. Arguments are handled as with +#free_places+.
    # 
    def nfree ids=nil
      free_places( ids ).names
    end
    alias free_pn nfree

    # Names of free places. Arguments are handled as with +#clamped_places+.
    # 
    def nclamped ids=nil
      clamped_places( ids ).names
    end
    alias clamped_pn nclamped

    protected

    # Place instance identification.
    # 
    def place( id )
      begin
        Place().instance( id )
      rescue NameError, TypeError
        begin
          pl = net.place( id )
          places.find { |p_rep| p_rep.source == pl } ||
            Place().instance( pl.name )
        rescue NameError, TypeError => msg
          raise
          raise TypeError, "The argument #{id} (class #{id.class}) does not identify a " +
            "place instance! (#{msg})"
        end
      end
    end

    # Without arguments, returns all the places. If arguments are given, they
    # are converted to places before being returned.
    # 
    def places( ids=nil )
      return @places if ids.nil?
      Places().load( ids.map { |id| place id } )
    end

    # Free places. If arguments are given, they must be identify free places,
    # and are converted to them.
    # 
    def free_places ids=nil
      return places.free if ids.nil?
      places.free.subset( ids )
    end

    # Clamped places. If arguments are given, they must be identify clamped
    # places, and are converted to them.
    # 
    def clamped_places ids=nil
      return places.clamped if ids.nil?
      places.clamped.subset( ids )
    end
  end # module Access
end # class YPetri::Simulation::Places
