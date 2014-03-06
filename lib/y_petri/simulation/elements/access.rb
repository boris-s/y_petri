#encoding: utf-8

# Simulation mixin providing access to elements (an element is either a
# place, or a transition -- see also mixins +Places::Access+ and
# +Transitions::Access+.
# 
class YPetri::Simulation::Elements
  module Access
    # Does an element belong to the simulation?
    # 
    def includes?( id )
      includes_place?( id ) || includes_transition?( id )
    end
    alias include? includes?

    # Element of the simulation belonging to the net. Each simulation has its
    # representations of places and transitions, which are based on the places
    # and transitions of the underlying net. This method takes one argument,
    # which (place, place name, transition, or transition name) and returns the
    # corresponding element of the underlying net.
    # 
    def e( place_or_transition )
      element( place_or_transition ).source
    end

    # Elements of the simulation (belonging to the net). Expects a single array
    # of elements (places & transitions) or element ids and returns an array of
    # the corresponding elements in the underlying net.
    # 
    def Ee( array )
      Elements( array ).sources
    end

    # Without arguments, returns all the places and transitions of the underlying
    # net. Otherwise, it accepts an arbitrary number of elements or element ids
    # as arguments, and returns an array of the corresponding places and
    # transitions of the underlying net.
    # 
    def ee( *elements )
      elements( *elements ).sources
    end

    # Names of the simulation's elements. Arguments, if any, are treated
    # analogically to the +#elements+ method.
    # 
    def en *elements
      ee( *elements ).names
    end

    protected

    # Element instance identification.
    # 
    def element( element )
      return place element if include_place? element
      return transition element if include_transition? element
      fail TypeError, "No element #{element} in the simulation!"
    end

    # Expects a single array of elements (places & transitions) or element
    # ids and returns an array of the corresponding places and transitions.
    # 
    def Elements( array )
      # NOTE: At the moment, the Simulation instance does not have a
      # parametrized sublclass of Simulation::Elements class, the followin
      # statement is thus made to return a plain array of elements.
      Elements().load array.map &method( :element )
    end

    # Without arguments, returns all the elements (places and transitions) of
    # the simulation. Otherwise, it accepts an arbitrary number of elements
    # or element ids as arguments, and returns an array of the corresponding
    # places and transitions of the simulation.
    # 
    def elements( *elements )
      return places + transitions if elements.empty?
      Elements( elements )
    end
  end # module Access
end # class YPetri::Simulation::Elements
