#encoding: utf-8

# Manages the initial marking of a simulation.
#
class YPetri::Simulation
  class InitialMarking < Hash
    include DependencyInjection

    # Initializes the initial marking from a hash.
    # 
    def self.load initial_marking_hash
      new.tap do |instance|
        initial_marking_hash.with_values do |v|
          # Unwrap places / closures:
          v = v.marking if v.is_a? YPetri::Place
          if v.is_a? Proc then v.call else v end
        end.tap &instance.method( :load )
      end
    end

    alias places keys
    alias with_place_names keys_to_names

    # Returns the initial marking as a column vector.
    # 
    def vector
      values.to_column_vector
    end
    alias to_column_vector vector

    # Sets the initial marking for a given place to a given value.
    # 
    def set( place_id, to: (fail ArgumentError) )
      pl = place( place_id )
      fail TypeError, "The place #{pl} is already clamped!" if
        begin; pl.clamped?; rescue TypeError, NoMethodError; end
      update pl => to
    end

    # Loads initial marking setting from a hash { place => value }
    # 
    def load( initial_marking_hash )
      initial_marking_hash.each_pair { |pl, value| set( pl, to: value ) }
    end

    # Fetches the initial marking of an identified place.
    # 
    def of( place_id )
      fetch place( place_id )
    end

    # Deletes the initial marking for a place.
    # 
    def delete( place_id )
      super place( place_id )
    end
  end # class InitialMarking
end # class YPetri::Simulation
