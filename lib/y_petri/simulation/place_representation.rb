#encoding: utf-8

# Representation of a YPetri::Place inside a YPetri::Simulation instance.
# 
class YPetri::Simulation
  class PlaceRepresentation < ElementRepresentation
    attr_reader :quantum

    # Index.
    # 
    def m_vector_index
      places.index( self )
    end

    # Expect a single YPetri place as an argument.
    # 
    def initialize net_place
      super
      @quantum = source.quantum
    end

    # Setter of clamp.
    # 
    def clamp=( value )
      simulation.set_marking_clamp( self, to: value )
    end

    # Setter of initial marking.
    # 
    def initial_marking=( value )
      simulation.set_initial_marking( self, to: value )
    end

    # Marking clamp value (or nil, if the place is clamped).
    # 
    def marking_clamp
      simulation.marking_clamp( self ) if clamped?
    end
    alias clamp marking_clamp

    # Initial marking value (or nil, if the place is free).
    # 
    def initial_marking
      simulation.initial_marking( self ) if free?
    end

    # Is the place free in the current simulation?
    # 
    def free?
      simulation.initial_markings.places.include? self
    end

    # Is the place clamped in the current simulation?
    # 
    def clamped?
      simulation.marking_clamps.places.include? self
    end

    # Set the marking of this place in the simulation.
    # 
    def m=( value )
      m_vector.set self, value
    end

    # Alias of #m=
    # 
    def marking=( value )
      m=( value )
    end

    # Get the current marking of this place in the simulation.
    # 
    def m
      m_vector[ self ]
    end
    alias marking m
  end # class PlaceRepresentation
end # class YPetri::Simulation
