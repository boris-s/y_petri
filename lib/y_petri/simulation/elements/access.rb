#encoding: utf-8

# Simulation mixin providing access to elements (an element is either a
# place, or a transition -- see also mixins +Places::Access+ and
# +Transitions::Access+.
# 
class YPetri::Simulation::Elements
  module Access
    # Element instance identification.
    # 
    def element( id )
      return place( id ) if includes_place?( place( id ) )
      return transition( id ) if includes_transition?( transition( id ) )
      fail TypeError, "No element #{id} in the simulation!"
    end
  
    # Does an element belong to the simulation?
    # 
    def includes?( id )
      includes_place?( id ) || includes_transition?( id )
    end
    alias include? includes?

    # Without arguments, returns all the elements (places + transitions). If
    # arguments are given, they are converted into elements.
    # 
    def elements *ids
      return places + transitions if ids.empty?
      ids.map { |id| element( id ) }
    end

    # Names of the simulation's elements. Arguments, if any, are treated
    # analogically to the +#elements+ method.
    # 
    def en *ids
      elements( *ids ).names
    end
    alias n_elements en
  end # module Access
end # class YPetri::Simulation::Elements
