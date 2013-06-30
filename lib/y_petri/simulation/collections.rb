#encoding: utf-8

# Mixin that provides methods exposing place and transition collections to
# YPetri::Simulation.
#
class YPetri::Simulation
  module Collections
    # Returns the simulation's places. Optional arguments / block make it return
    # a hash <tt>places => values</tt>, such as:
    #
    #   places :marking
    #   #=> { <Place:Foo> => 42, <Place:Bar> => 43, ... }
    # 
    def places *aa, &b
      return @places.dup if aa.empty? && b.nil?
      zip_to_hash places, *aa, &b
    end

    # Returns the simulation's transitions. Optional arguments / block make it
    # return a hash <tt>places => values</tt>, such as:
    #
    # transitions :flux
    # #=> { <Transition:Baz> => 42, <Transition:Quux => 43, ... }
    # 
    def transitions *aa, &b
      return @transitions.dup if aa.empty? && b.nil?
      zip_to_hash transitions, *aa, &b
    end

    # Like #places method, except that in the output, names are used instead of
    # place instances when possible.
    # 
    def pp *aa, &b
      return places.map &:name if aa.empty? && b.nil?
      zip_to_hash( places.map { |p| p.name || p }, *aa, &b )
    end

    # Like #transitions method, except that in the output, names are used
    # instead of transition instances when possible.
    # 
    def tt *aa, &b
      return transitions.map &:name if aa.empty? && b.nil?
      zip_to_hash( transitions.map { |t| t.name || t }, *aa, &b )
    end

    # Returns the simulation's free places, with same syntax options as #places
    # method.
    # 
    def free_places *aa, &b
      return zip_to_hash free_places, *aa, &b unless aa.empty? && b.nil?
      kk = @initial_marking.keys
      places.select { |p| kk.include? p }
    end

    # Like #free_places, except that in the output, names are used instead of
    # place instances when possible.
    # 
    def free_pp *aa, &b
      return free_places.map { |p| p.name || p } if aa.empty? && b.nil?
      zip_to_hash free_pp, *aa, &b
    end

    # Initial marking definitions for free places (as array).
    # 
    def im
      free_places.map { |p| @initial_marking[p] }
    end

    # Marking array of all places as it appears at the beginning of a simulation.
    # 
    def initial_marking
      raise # FIXME: "Initial marking" for all places (ie. incl. clamped ones).
    end

    # Initial marking of free places (as column vector).
    # 
    def im_vector
      Matrix.column_vector im
    end
    alias iᴍ im_vector

    # Marking of all places at the beginning of a simulation (as column vector).
    # 
    def initial_marking_vector
      Matrix.column_vector initial_marking
    end

    # Returns the simulation's clamped places, with same syntax options as #places
    # method.
    # 
    def clamped_places *aa, &b
      return zip_to_hash clamped_places, *aa, &b unless aa.empty? && b.nil?
      kk = @marking_clamps.keys
      places.select { |p| kk.include? p }
    end

    # Like #clamped_places, except that in the output, names are used instead of
    # place instances whenever possible.
    # 
    def clamped_pp *aa, &b
      return clamped_places.map { |p| p.name || p } if aa.empty? && b.nil?
      zip_to_hash clamped_pp, *aa, &b
    end

    # Place clamp definitions for clamped places (as array)
    # 
    def marking_clamps
      clamped_places.map { |p| @marking_clamps[p] }
    end
    alias place_clamps marking_clamps

    # Marking of free places (as array).
    # 
    def m
      m_vector.column_to_a
    end

    # Marking of free places (as hash of pairs <tt>{ name: marking }</tt>).
    # 
    def pm
      free_pp :m
    end
    alias p_m pm

    # Marking of free places (as hash of pairs <tt>{ place: marking }</tt>.
    # 
    def place_m
      free_places :m
    end

    # Marking of all places (as array).
    # 
    def marking
      marking_vector ? marking_vector.column_to_a : nil
    end

    # Marking of all places (as hash of pairs <tt>{ name: marking }</tt>).
    # 
    def p_marking
      pp :marking
    end
    alias pmarking p_marking

    # Marking of all places (as hash of pairs <tt>{ place: marking }</tt>.
    # 
    def place_marking
      places :marking
    end

    # Marking of a specified place or a collection of places.
    # 
    def marking_of places
      m = place_marking
      return places.map { |pl| m[ place( pl ) ] } if places.respond_to? :each
      m[ place( place_or_places ) ]
    end
    alias m_of marking_of

    # Marking of free places ( as column vector).
    # 
    def m_vector
      F2A().t * @marking_vector
    end
    alias ᴍ m_vector

    # Marking of clamped places (as column vector).
    # 
    def marking_vector_of_clamped_places
      C2A().t * @marking_vector
    end
    alias ᴍ_clamped marking_vector_of_clamped_places

    # Marking of clamped places (as array).
    # 
    def marking_of_clamped_places
      marking_vector_of_clamped_places.column( 0 ).to_a
    end
    alias m_clamped marking_of_clamped_places

    # Returns a stoichiometry matrix for an arbitrary array of stoichiometric
    # transitions. The returned stoichiometry matrix has the number of columns
    # equal to the number of supplied stoichimetric transitions, and the number
    # of rows equal to the number of free places. When multiplied by a vector
    # corresponding to the transitions (such as flux vector), the resulting
    # column vector corresponds to the free places.
    # 
    def S_for( stoichiometric_transitions )
      stoichiometric_transitions.map { |t| sparse_σ t }
        .reduce( Matrix.empty( free_places.size, 0 ), :join_right )
    end

    # Returns a stoichiometry matrix for an arbitrary array of stoichiometric
    # transitions. Behaves like +#S_for+ method, with the difference that the
    # rows correspond to _all_ places, not just free places.
    # 
    def stoichiometry_matrix_for( stoichiometric_transitions )
      stoichiometric_transitions.map { |t| sparse_stoichiometry_vector t }
        .reduce( Matrix.empty( places.size, 0 ), :join_right )
    end

    # Stoichiometry matrix of this simulation. By calling this method, the
    # caller asserts, that all transitions in this simulation are SR transitions
    # (or error).
    # 
    def S
      return S_SR() if s_transitions.empty? && r_transitions.empty?
      raise "The simulation contains also non-stoichiometric transitions! " +
        "Consider using #S_for_SR."
    end

    # ==== ts transitions

    # Returns the simulation's *ts* transitions, with syntax options like
    # #transitions method.
    # 
    def ts_transitions *aa, &b
      return zip_to_hash ts_transitions, *aa, &b unless aa.empty? && b.nil?
      sift_from_net :ts_transitions
    end

    # Like #ts_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def ts_tt *aa, &b
      return zip_to_hash ts_tt, *aa, &b unless aa.empty? && b.nil?
      ts_transitions.map { |t| t.name || t }
    end

    # Returns the simulation's *non-assignment* *ts* transtitions, with syntax
    # options like #transitions method. While *A* transitions can be regarded
    # as a special kind of *ts* transitions, it may often be useful to separate
    # them out from the collection of "ordinary" *ts* transtitions (*tsa*
    # transitions).
    # 
    def tsa_transitions *aa, &b
      return zip_to_hash tsa_transitions, *aa, &b unless aa.empty? && b.nil?
      sift_from_net :tsa_transitions
    end

    # Like #tsa_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def tsa_tt *aa, &b
      return zip_to_hash tsa_tt, *aa, &b unless aa.empty? && b.nil?
      tsa_transitions.map { |t| t.name || t }
    end

    # ==== tS transitions

    # Returns the simulation's *tS* transitions, with syntax options like
    # #transitions method.
    # 
    def tS_transitions *aa, &b
      return zip_to_hash tS_transitions, *aa, &b unless aa.empty? && b.nil?
      sift_from_net :tS_transitions
    end

    # Like #tS_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def tS_tt *aa, &b
      return zip_to_hash tS_tt, *aa, &b unless aa.empty? && b.nil?
      tS_transitions.map { |t| t.name || t }
    end

    # ==== Tsr transitions

    # Returns the simulation's *Tsr* transitions, with syntax options like
    # #transitions method.
    # 
    def Tsr_transitions *aa, &b
      return zip_to_hash Tsr_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :Tsr_transitions
    end

    # Like #Tsr_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def Tsr_tt *aa, &b
      return zip_to_hash Tsr_tt(), *aa, &b unless aa.empty? && b.nil?
      Tsr_transitions().map { |t| t.name || t }
    end

    # ==== TSr transitions

    # Returns the simulation's *TSr* transitions, with syntax options like
    # #transitions method.
    # 
    def TSr_transitions *aa, &b
      return zip_to_hash TSr_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :TSr_transitions
    end

    # Like #TSr_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def TSr_tt *aa, &b
      return zip_to_hash TSr_tt(), *aa, &b unless aa.empty? && b.nil?
      TSr_transitions().map { |t| t.name || t }
    end

    # ==== sR transitions

    # Returns the simulation's *sR* transitions, with syntax options like
    # #transitions method.
    # 
    def sR_transitions *aa, &b
      return zip_to_hash sR_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :sR_transitions
    end

    # Like #sR_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def sR_tt *aa, &b
      return zip_to_hash sR_tt(), *aa, &b unless aa.empty? && b.nil?
      sR_transitions.map { |t| t.name || t }
    end

    # ==== SR transitions

    # Returns the simulation's *SR* transitions, with syntax options like
    # #transitions method.
    # 
    def SR_transitions *aa, &b
      return zip_to_hash SR_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :SR_transitions
    end

    # Like #SR_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def SR_tt *aa, &b
      return zip_to_hash SR_tt(), *aa, &b unless aa.empty? && b.nil?
      SR_transitions().map { |t| t.name || t }
    end

    # ==== Assignment (A) transitions

    # Returns the simulation's *A* transitions, with syntax options like
    # #transitions method.
    # 
    def A_transitions *aa, &b
      return zip_to_hash A_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :A_transitions
    end
    alias assignment_transitions A_transitions

    # Like #A_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def A_tt *aa, &b
      return zip_to_hash A_tt(), *aa, &b unless aa.empty? && b.nil?
      A_transitions().map { |t| t.name || t }
    end
    alias assignment_tt A_tt

    # ==== Stoichiometric transitions of arbitrary type (S transitions)

    # Returns the simulation's *S* transitions, with syntax options like
    # #transitions method.
    # 
    def S_transitions *aa, &b
      return zip_to_hash S_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :S_transitions
    end

    # Like #S_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def S_tt *aa, &b
      return zip_to_hash S_tt(), *aa, &b unless aa.empty? && b.nil?
      S_transitions().map { |t| t.name || t }
    end

    # ==== Nonstoichiometric transitions of arbitrary type (s transitions)

    # Returns the simulation's *s* transitions, with syntax options like
    # #transitions method.
    # 
    def s_transitions *aa, &b
      return zip_to_hash s_transitions, *aa, &b unless aa.empty? && b.nil?
      sift_from_net :s_transitions
    end

    # Like #s_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def s_tt *aa, &b
      return zip_to_hash s_tt, *aa, &b unless aa.empty? && b.nil?
      s_transitions.map { |t| t.name || t }
    end

    # ==== Transitions with rate of arbitrary type (R transitions)

    # Returns the simulation's *R* transitions, with syntax options like
    # #transitions method.
    # 
    def R_transitions *aa, &b
      return zip_to_hash R_transitions(), *aa, &b unless aa.empty? && b.nil?
      sift_from_net :R_transitions
    end

    # Like #R_transitions, except that in the output, names are used instead
    # of instances when possible.
    # 
    def R_tt *aa, &b
      return zip_to_hash R_tt(), *aa, &b unless aa.empty? && b.nil?
      R_transitions().map { |t| t.name || t }
    end

    # ==== Rateless transitions of arbitrary type (r transitions)

    # Returns the simulation's *r* transitions, with syntax options like
    # #transitions method.
    # 
    def r_transitions *aa, &b
      return zip_to_hash r_transitions, *aa, &b unless aa.empty? && b.nil?
      sift_from_net :r_transitions
    end

    # Like #r_transitions, except that transition names are used instead of
    # instances, whenever possible.
    # 
    def r_tt *aa, &b
      return zip_to_hash r_tt, *aa, &b unless aa.empty? && b.nil?
      r_transitions.map { |t| t.name || t }
    end

    private

    # This helper method takes a collection, a variable number of other arguments
    # and an optional block, and returns a hash whose keys are the collection
    # members, and whose values are given by the supplied othe arguments and/or
    # block in the following way: If there is no additional argument, but a block
    # is supplied, this is applied to the collection. If there is exactly one
    # other argument, and it is also a collection, it is used as values.
    # Otherwise, these other arguments are treated as a message to be sent to
    # self (via #send), expecting it to return a collection to be used as hash
    # values. Optional block (which is always assumed to be unary) can be used
    # to additionally modify the second collection.
    # 
    def zip_to_hash collection, *args, &block
      sz = args.size
      values = if sz == 0 then collection
               elsif sz == 1 && args[0].respond_to?( :each ) then args[0]
               else send *args end
      Hash[ collection.zip( block ? values.map( &block ) : values ) ]
    end

    # Chicken approach towards ensuring that transitions in question come in
    # the same order as in @transitions local variable. Takes a symbol as the
    # argument (:SR, :TSr, :sr etc.)
    # 
    def sift_from_net type_of_transitions
      from_net = net.send type_of_transitions
      @transitions.select { |t| from_net.include? t }
    end
  end # module Collections
end # class YPetri::Simulation
