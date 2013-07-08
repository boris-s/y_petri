#encoding: utf-8

# Representation of a YPetri::Place inside a YPetri::Simulation instance.
#
class YPetri::Simulation
  class PlaceRepresentation
    include NameMagic
    include DependencyInjection

    attr_reader :source # source place
    attr_reader :m_vector_index

    # Expect a single YPetri place as an argument.
    # 
    def initialize net_place
      @source = net.place( net_place )
      @m_vector_index = net.places.index( source )
    end

    # Setter of clamp.
    # 
    def clamp=( value )
      simulation.set_marking_clamp( of: self, to: value )
    end

    # Setter of initial marking.
    # 
    def initial_marking=( value )
      simulation.set_initial_marking( of: self, to: value )
    end

    # Marking clamp value (or nil, if the place is clamped).
    # 
    def marking_clamp
      simulation.marking_clamp( of: self ) if clamped?
    end
    alias clamp marking_clamp

    # Initial marking value (or nil, if the place is free).
    # 
    def initial_marking
      simulation.initial_marking( of: self ) if free?
    end

    # Is the place free in the current simulation?
    # 
    def free?
      simulation.initial_marking.places.include? self
    end

    # Is the place clamped in the current simulation?
    # 
    def clamped?
      simulation.marking_clamps.places.include? self
    end

    # Set the marking of this place in the simulation.
    # 
    def m=( value )
      simulation.m_vector.send :[]=, m_vector_index, 0, value
    end

    # Alias of #m=
    # 
    def marking=( value )
      m=( value )
    end

    # Get the current marking of this place in the simulation.
    # 
    def m
      simulation.m_vector[ m_vector_index, 0 ]
    end
    alias marking m
  end # class PlaceRepresentation
end # class YPetri::Simulation
