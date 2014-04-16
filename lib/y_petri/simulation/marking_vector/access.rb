#encoding: utf-8

# A mixin to +YPetri::Simulation+.
# 
class YPetri::Simulation::MarkingVector
  module Access
    # Marking of the selected places as a column vector. Expects a single array
    # argument.
    # 
    def M_vector array
      m_vector.select( array )
    end
    alias m_Vector M_vector

    # Acts as a getter of the simulation's state vector, instance variable
    # +@m_vector+.
    # 
    def state
      @m_vector or fail TypeError, "State not constructed yet!"
    end

    # Convenience method that accepts any number of places or place ids as
    # arguments, and returns their marking as a column vector. If no arguments
    # are supplied, the method returns the simulation's state vector.
    # 
    def m_vector *places
      begin
      return state if places.empty?
      m_vector.select( places )
      end
    end

    # Array-returning equivalents of +#M_vector+ and +m_vector+.
    # 
    def M *args; M_vector( *args ).to_a end
    def m *args; m_vector( *args ).to_a end


    # map! M: :M_vector,
    #      m: :m_vector,
    #      &:column_to_a

    # Hash-returning { place => marking } equivalents Marking of all places
    # (as hash).
    # 
    chain Place_m: :M_vector,
          place_m: :m_vector,
          &:to_hash
    alias place_M Place_m

    # Marking of the indicated places as a hash of { place name => marking }
    # pairs. Expects a single array of places or place ids as an argument.
    # 
    def P_m places
      Places( places ).names( true ) >> M( places )
    end
    alias p_M P_m
    alias Pn_m P_m

    # Marking of the indicated places as a hash of { place name => marking }
    # pairs. Expects and arbitrary number of places or place ids and arguments.
    # If no arguments are given, marking of all the places is returned.
    # 
    def p_m *places
      places( *places ).names( true ) >> m( *places )
    end
    alias pn_m p_m

    # Pretty prints marking of the indicated places. Expects an array of places
    # or place ids as an argument. In addition, accepts 2 optional named
    # arguments, +:gap+ and +:precision+ (alias +:p+), that control the layout
    # of the printed table, like in +#pretty_print_numeric_values+ method.
    # 
    def Pm places, **named_args
      gap = named_args[:gap] || 0
      named_args.may_have :precision, syn!: :pn
      precision = named_args.delete( :precision ) || 3
      P_m( places ).pretty_print_numeric_values gap: gap, precision: precision
    end

    # Pretty prints marking of the indicated places. Expects an arbitrary number
    # of places or place ids, and 2 optional named arguments, +:gap+ and
    # +:precision+ (alias +:p+), that control the layout of the printed table,
    # like in +#pretty_print_numeric_values+ method.
    # 
    def pm *places, **named_args
      return Pm places() if places.empty?
      Pm( places, **named_args )
    end

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
      return nil
    end
    alias set_m update_m

    # Marking vector of free places. Expects an array of places or place ids, for
    # which the marking vectro is returned.
    # 
    def Marking_vector array
      M_vector Free_places( array )
    end

    # Marking vector of free places. Expects an arbitrary number of free places
    # or place ids and returns the marking vector for them.
    # 
    def marking_vector *places
      m_vector *free_places( *places )
    end

    # Array-returning versions of +#Marking_vector+ and +#marking_vector+.
    # 
    chain Marking: :Marking_vector,
          marking: :marking_vector,
          &:to_a

    # Versions of +#Marking_vector+ and +#marking_vector+ that return hash of
    # { place => marking } pairs.
    # 
    chain Place_marking: :Marking_vector,
          place_marking: :marking_vector,
          &:to_hash

    # Versions of +#Marking_vector+ and +#marking_vector+ that return hash of
    # { place name => marking } pairs.
    # 
    chain P_marking: :Marking_vector,
          p_marking: :marking_vector,
          &:to_h
    alias Pn_marking P_marking
    alias pn_marking p_marking

    # Modifies the marking vector. Like +#update_m+, but the places must be
    # free places, and if the argument is an array, it must match the number
    # of free places in the simulation's net.
    # 
    def update_marking new_m
      case new_m
      when Hash then # assume { place => marking } hash
        ( free_places( new_m.keys ) >> new_m.values )
          .each_pair { |id, val| m_vector.set( id, val ) }
      when Array then
        msg = "T be a collection with size == number of net's free places!"
        fail TypeError, msg unless new_m.size == free_places.size
        update_m( free_places >> new_m )
      else # convert it with #each
        update_marking( new_m.each.to_a )
      end
      return nil
    end
    alias set_marking update_marking

    # Expects a Δ marking vector for free places and performs the specified
    # change on the marking vector of the simulation.
    # 
    def increment_marking Δ_free
      @m_vector += f2a * Δ_free
      return nil
    end
  end # module Access
end # class YPetri::Simulation::MarkingVector
