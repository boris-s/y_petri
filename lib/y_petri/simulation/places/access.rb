#encoding: utf-8

# Simulation mixin providing access to places.
#
class YPetri::Simulation::Places
  module Access
    # With no arguments, acts as a reader of f2a -- the correspondence matrix
    # between free places and all places. If argument is given, it is assumed
    # to be a column vector, and multiplication with f2a is performed.
    # 
    def f2a arg=nil
      arg.nil? ? @f2a : @f2a * arg
    end

    # With no arguments, acts as a reader of c2a -- the correspondence matrix
    # between clamped places and all places. If argument is given, it is assumed
    # to be a column vector, and multiplication with c2a is performed.
    # 
    def c2a arg=nil
      arg.nil? ? @c2a : @c2a * arg
    end

    # Does a place belong to the simulation?
    # 
    def includes_place? place
      true.tap { begin; place place; rescue NameError, TypeError
                   return false
                 end }
    end
    alias include_place? includes_place?

    # Place of the simulation (belonging to the net).
    # 
    def p( place )
      place( place ).source
    end

    # Places of the simulation (belonging to the net).
    # 
    def pp( places=nil )
      places( places ).sources
    end

    # Free places of the simulation (belonging to the net).
    # 
    def free_pp( free_places=nil )
      free_places( free_places ).sources
    end

    # Clamped places of the simulation (belonging to the net).
    # 
    def clamped_pp( clamped_places=nil )
      clamped_places( clamped_places ).sources
    end

    # Names of specified places.
    # 
    def pn( places=nil )
      places( places ).names( true )
    end

    # Names of specified free places.
    # 
    def nfree free_places=nil
      free_places( free_places ).names( true )
    end
    alias free_pn nfree

    # Names of specified clamped places.
    # 
    def nclamped clamped_places=nil
      clamped_places( clamped_places ).names( true )
    end
    alias clamped_pn nclamped

    protected

    # Place instance identification.
    # 
    def place( place )
      begin; Place().instance( place ); rescue NameError, TypeError
        begin
          place = net.place( place )
          places.find { |place_rep| place_rep.source == place } ||
            Place().instance( place.name )
        rescue NameError, TypeError => msg
          raise # FIXME: This raise needs to be here in order for the current
          # tests to pass (they expect NameError, while the raise below would
          # raise TypeError). But it is not clear to me anymore why the tests
          # require NameError in the first place. Gotta look into it.
          raise TypeError, "The argument #{place} (class #{place.class}) does " +
            "not identify a place instance! (#{msg})"
        end
      end
    end

    # Constructs a @Places instance. Note that the includer of the
    # +Places::Access+ module overloads :Places message without arguments
    # with the getter of the @Places parametrized subclass itself.
    # 
    def Places places
      Places().load places.map &method( :place )
    end

    # Without arguments, returns all the places. If arguments are given, they
    # are converted to places before being returned.
    # 
    def places( places=nil )
      places.nil? ? @places : Places( places )
    end

    # Free places. If arguments are given, they must be identify free places,
    # and are converted to them.
    # 
    def free_places free_places=nil
      free_places.nil? ? places.free : places.free.subset( free_places )
    end

    # Clamped places. If arguments are given, they must be identify clamped
    # places, and are converted to them.
    # 
    def clamped_places clamped_places=nil
      clamped_places.nil? ? places.clamped :
        places.clamped.subset( clamped_places )
    end

    # # TODO: This is my new concept of how #places vs. #Places should work. Won't
    # # develop it now, but later, there will be 2 kinds of convenience constructors:
    # # Places( [ p1, p2, p3 ] ) and places( p1, p2, p3 ), where Places() is overloaded
    # # with getting the @Places parametrized subclass itself, while places() is
    # # overloaded with getting the complete set of simulation's places. This is
    # # convenient, but programatically inconsistent, since the method does something
    # # completely else when the set of places happens to be empty. For programmatically
    # # consistent way of construction a collection of places, use Places( [ *collection ] ).

    # # Without arguments, returns all the places. If arguments are given, they
    # # are converted to places before being returned.
    # # 
    # def places( *places )
    #   places.empty? ? @places : Places( places )
    # end
  end # module Access
end # class YPetri::Simulation::Places
