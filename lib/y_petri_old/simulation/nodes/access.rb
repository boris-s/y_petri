#encoding: utf-8

# Simulation mixin providing access to nodes (places / transitions). Also see
# mixins +Places::Access+ and +Transitions::Access+.
# 
class YPetri::Simulation::Nodes
  module Access
    # Does a node belong to the simulation?
    # 
    def includes?( id )
      includes_place?( id ) || includes_transition?( id )
    end
    alias include? includes?

    # Node of the simulation belonging to the net. Each simulation has its
    # representations of places and transitions, which are based on the places
    # and transitions of the underlying net. This method takes one argument,
    # which (place, place name, transition, or transition name) and returns the
    # corresponding node of the underlying net.
    # 
    def n( node )
      node( node ).source
    end

    # Nodes of the simulation (belonging to the net). Expects a single array of
    # nodes (places / transitions) or node ids and returns an array of the
    # corresponding nodes in the underlying net.
    # 
    def Nn( array )
      Nodes( array ).sources
    end

    # Without arguments, returns all the nodes of the underlying net. Otherwise,
    # it accepts an arbitrary number of nodes or node ids as arguments, and
    # returns an array of the corresponding nodes of the underlying net.
    # 
    def nn( *nodes )
      nodes( *nodes ).sources
    end

    # Names of the simulation's nodes. Arguments, if any, are treated
    # analogically to the +#nodes+ method.
    # 
    def nnn *nodes
      nnn( *nodes ).names
    end

    protected

    # Node instance identification.
    # 
    def node( node )
      return place node if include_place? node
      return transition node if include_transition? node
      fail TypeError, "No node #{node} in the simulation!"
    end

    # Expects a single array of nodes (places / transitions) or node ids and
    # returns an array of the corresponding node instances.
    # 
    def Nodes( array )
      # NOTE: At the moment, the Simulation instance does not have a
      # parametrized subclass of Simulation::Nodes class, the following
      # statement is thus made to return a plain array of elements.
      Nodes().load array.map &method( :node )
    end

    # Without arguments, returns all the nodes (places / transitions) of the
    # simulation. Otherwise, it accepts an arbitrary number of nodes or node ids
    # as arguments, and returns an array of the corresponding nodes of the
    # simulation.
    # 
    def nodes( *nodes )
      return places + transitions if nodes.empty?
      Nodes( nodes )
    end
  end # module Access
end # class YPetri::Simulation::Nodes
