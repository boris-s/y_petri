#encoding: utf-8

# Simulation mixin providing access to the initial marking.
#
class YPetri::Simulation::InitialMarking
  module Access
    # Without arguments, acts as a getter of @initial_marking. If arguments are
    # supplied, they must identify free places, and are mapped to their initial
    # marking.
    # 
    def initial_marking ids=nil
      if ids.nil? then
        @initial_marking or
          fail TypeError, "InitialMarking object not instantiated yet!"
      else
        free_places( ids ).map { |pl| initial_marking[ place( pl ) ] }
      end
    end

    # Without arguments, returns the marking of all the simulation's places
    # (both free and clamped) as it appears after reset. If arguments are
    # supplied, they must identify places, and are converted to either their
    # initial marking (free places), or their clamp value (clamped places).
    # 
    def im ids=nil
      return im( places ) if ids.nil?
      places( ids ).map { |pl|
        pl.free? ? initial_marking( of: pl ) : marking_clamp( of: pl )
      }
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
    def set_initial_marking( of: (fail ArgumentError), to: (fail ArgumentError) )
      initial_marking.set( of, to: to )
    end
  end # module Access
end # class YPetri::Simulation::InitialMarking

