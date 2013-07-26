# Manages the initial marking of a simulation.
# 
class YPetri::Simulation
  class PlaceMapping < Hash
    include Dependency

    class << self
      # Initializes the initial marking from a hash.
      # 
      def load hash
        new.tap do |inst|
          hash.with_values do |v|
            v = v.marking if v.is_a? YPetri::Place
            if v.is_a? Proc then v.call else v end
          end.tap &inst.method( :load )
        end
      end
    end

    delegate :simulation, to: :class

    alias places keys

    # Returns the initial marking as a column vector.
    # 
    def vector
      simulation.MarkingVector[ self ]
    end
    alias to_marking_vector vector

    # Sets the mapping value for a given place to a given value.
    # 
    def set place_id, to: (fail ArgumentError, "No :to value!")
      update place( place_id ) => to
    end

    # Loads initial the mappings from a hash places >> values.
    # 
    def load( hash )
      hash.each { |place, value| set place, to: value }
    end

    # Fetches the value for a place.
    # 
    def of place_id
      fetch place( place_id )
    end

    # Deletes the value for a place.
    # 
    def delete place_id
      super place( place_id )
    end

    # Returns a hash, whose keys have been replaced with source places of
    # the place representations in this place mapping.
    # 
    def keys_to_source_places
      with_keys do |key| key.source end
    end
  end # class InitialMarking
end # class YPetri::Simulation
