#encoding: utf-8

# Collection of marking clamps for YPetri::Simulation.
#
class YPetri::Simulation
  class MarkingClamps < Hash
    include DependencyInjection

    # Initializes the marking clamps from a hash.
    # 
    def self.load marking_clamp_hash
      new.tap do |instance|
        marking_clamp_hash.with_values do |clamp|
          # Unwrap places / closures:
          clamp = clamp.marking if clamp.is_a? YPetri::Place
          if clamp.is_a? Proc then clamp.call else clamp end
        end.tap &instance.method( :load )
      end
    end

    alias places keys

    # Returns the marking clamp values as a column vector.
    # 
    def vector
      values.to_column_vector
    end

    # Returns the hash with place names instead of places.
    # 
    def name_hash
      places.names( true ) >> values
    end

    # Sets the clamp for a given place to a given value.
    # 
    def set( place_id, to: (fail ArgumentError) )
      pl = place( place_id )
      # Free places change into clamped ones.
      initial_marking.delete( pl ) if
        begin; pl.free?; rescue TypeError, NoMethodError; end
      update pl => to
    end

    # Loads the clamps' setting from a hash { place => value }
    # 
    def load( clamp_hash )
      clamp_hash.each_pair { |pl, value| set( pl, to: value ) }
    end

    # Fetches the clamp of an identified place.
    # 
    def clamp_of( place_id )
      fetch place( place_id )
    end

    # Deletes the clamp for a place.
    # 
    def delete( place_id )
      super place( place_id )
    end
  end # class MarkingClamps
end # class YPetri::Simulation
