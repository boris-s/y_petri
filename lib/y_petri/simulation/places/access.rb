# encoding: utf-8

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

    # Net's place.
    # 
    def p( place )
      place( place ).source
    end

    # Makes it so that when "places" is abbreviated to "pp", places of the
    # underlying net are returned rather than simulation's place representations.
    # 
    chain Pp: :Places,
          pp: :places,
          Free_pp: :Free_places,
          free_pp: :free_places,
          Clamped_pp: :Clamped_places,
          clamped_pp: :clamped_places,
          &:sources

    alias free_Pp Free_pp
    alias clamped_Pp Clamped_pp

    # Makes it so that +Pn+/+pn+ means "names of places", and that when message
    # "n" + place_type is sent to the simulation, it returns names of the places
    # of the specified type.
    # 
    chain Pn: :Pt,
          pn: :pp,
          nfree: :free_places,
          nclamped: :clamped_places do |r| r.names( true ) end

    alias free_pn nfree
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

    # Constructs an instance of @Places parametrized subclass. Expects a single
    # array of places or place ids and returns an array of corresponding place
    # representations in the simulation. Note that the includer of the
    # +Places::Access+ module normally overloads :Places message in such way,
    # that even without an argument, it does not fail, but returns the @Places
    # parametrized subclass itself.
    # 
    def Places( array )
      # Kernel.p array
      Places().load array.map &method( :place )
    end

    # Without arguments, returns all the place representations in the simulation.
    # Otherwise, it accepts an arbitrary number of places or place ids as
    # arguments, and a corresponding array of place representations.
    # 
    def places( *places )
      return @places if places.empty?
      Places( places )
    end

    # Expects a single array of free places or place ids and returns an array of
    # the corresponding free place representations in the simulation.
    # 
    def Free_places( array )
      places.free.subset( array )
    end
    alias free_Places Free_places

    # Without arguments, returns all free places of the simulation. Otherwise, it
    # accepts an arbitrary number of free places or place ids as arguments, and
    # returns an array of the corresponding free places of the simulation.
    # 
    def free_places( *free_places )
      return places.free if free_places.empty?
      Free_places( free_places )
    end

    # Expects a single array of clamped places or place ids and returns an array
    # of the corresponding clamped place representations in the simulation.
    # 
    def Clamped_places( array )
      places.clamped.subset( array )
    end
    alias clamped_Places Clamped_places

    # Withoud arguments, returns all clamped places of the simulation. Otherwise,
    # it accepts an arbitrary number of clamped places or place ids as arguments,
    # and returns and array of the correspondingg clamped places.
    # 
    def clamped_places( *clamped_places )
      return places.clamped if clamped_places.empty?
      Clamped_places( clamped_places )
    end
  end # module Access
end # class YPetri::Simulation::Places
