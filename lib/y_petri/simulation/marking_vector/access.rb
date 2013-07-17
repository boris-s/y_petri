#encoding: utf-8

# A mixin.
# 
class YPetri::Simulation::MarkingVector
  module Access
    # Marking of all places (as a column vector).
    # 
    def m_vector ids=nil
      if ids.nil? then
        msg = "Marking vector not established yet!"
        @m_vector or fail TypeError, msg
      else
        m_vector.select( ids )
      end
    end

    # Marking of all places (as array).
    # 
    def m ids=nil
      m_vector( ids ).to_a
    end

    # Marking of all places (as hash).
    # 
    def place_m ids=nil
      m_vector( ids ).to_hash
    end
  
    # Marking of all places (as hash with place names as keys).
    # 
    def p_m ids=nil
      places( ids ).names( true ) >> m( ids )
    end
    alias pn_m p_m
    alias pm p_m

    # Modifies the marking vector. Takes one argument. If the argument is a hash
    # of pairs { place => new value }, only the specified places' markings are
    # updated. If the argument is an array, it must match the number of places
    # in the simulation, and all marking values are updated.
    # 
    def update_m new_m
      case new_m
      when Hash then # assume { place => marking } hash
        new_m.each_pair { |id, val| m_vector.set( id, val ) }
      when Array then
        msg = "T be a collection with size == number of net's places!"
        fail TypeError, msg unless new_m.size == places.size
        update_m( places >> new_m )
      else # convert it with #each
        update_m( new_m.each.to_a )
      end
    end

    # Marking vector of free places.
    # 
    def marking_vector ids=nil
      m_vector free_places( ids )
    end

    # Marking of free places (as array).
    # 
    def marking ids=nil
      marking_vector( ids ).to_a
    end

    # Marking of free places (as hash).
    # 
    def place_marking ids=nil
      marking_vector( ids ).to_hash
    end

    # Marking of free places (as hash with place names as keys).
    # 
    def p_marking ids=nil
      marking_vector( ids ).to_h
    end
    alias pn_marking p_marking

    # Modifies the marking vector. Like +#update_m+, but the places must be
    # free places, and if the argument is an array, it must match the number
    # of free places in the simulation's net.
    # 
    def update_marking new_m
      case new_m
      when Hash then # assume { place => marking } hash
        ( free_places( *new_m.keys ) >> new_m.values )
          .each_pair { |id, val| m_vector.set( id, val ) }
      when Array then
        msg = "T be a collection with size == number of net's free places!"
        fail TypeError, msg unless new_m.size == free_places.size
        update_m( free_places >> new_m )
      else # convert it with #each
        update_marking( new_m.each.to_a )
      end
    end

    # Expects a Δ marking vector for free places and performs the specified
    # change on the marking vector of the simulation.
    # 
    def increment_marking Δ_free
      @m_vector += f2a * Δ_free
    end
  end # module Access
end # class YPetri::Simulation::MarkingVector