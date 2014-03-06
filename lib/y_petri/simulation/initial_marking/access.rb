#encoding: utf-8

# Simulation mixin providing access to the initial marking.
#
class YPetri::Simulation::InitialMarking
  module Access
    # Expects a single array of free places or place ids, and returns an array
    # of their initial markings.
    # 
    def Initial_markings array
      Free_places( array ).map { |place| initial_marking[ place place ] }
    end
    alias initial_Markings Initial_markings

    # Expects an arbitrary number of arguments identifying free places, whose
    # initial markings are then returned. If no arguments are given, acts as
    # a getter of +@initial_marking+ instance variable.
    # 
    def initial_markings *free_places
      return initial_marking if free_places.empty?
      Initial_markings( free_places )
    end

    # Expects a single free place and returns the value of its initial marking.
    # 
    def initial_marking arg=L!
      return initial_markings( arg ).first unless arg.local_object?
      @initial_marking or fail TypeError, "+@initial_marking+ not present yet!"
    end

    # Expects a single array of places, and returns their marking as it would
    # appear right after the simulation reset.
    # 
    def Im array
      places( array ).map { |place|
        place.free? ? initial_marking( place ) : marking_clamp( place )
      }
    end

    # Expects an arbitrary number of places or place identifiers, and returns
    # their marking as it would appear right after the simulation reset. If no
    # arguments are given, returns all of them.
    # 
    def im *places
      return Im places() if places.empty?
      Im( places )
    end

    # Returns initial marking vector for free places. Like +#initial_marking+,
    # but returns a column vector.
    # 
    def initial_marking_vector ids=nil
      initial_marking( ids ).to_column_vector
    end

    # Returns initial marking vector for all places. Like +#initial_marking+,
    # but returns a column vector.
    # 
    def im_vector ids=nil
      im( ids ).to_column_vector
    end

    private

    # Sets the initial marking of a place (frontend of +InitialMarking#set+).
    # 
    def set_initial_marking( place, to: (fail ArgumentError) )
      initial_marking.set( place, to: to )
    end
  end # module Access
end # class YPetri::Simulation::InitialMarking
