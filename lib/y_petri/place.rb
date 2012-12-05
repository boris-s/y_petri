#encoding: utf-8

# A Petri net place.

module YPetri
  class Place
    USE_QUANTUM = false
    include ConstMagicErsatz

    attr_reader :quantum
    attr_accessor :default_marking
    attr_accessor :marking           # instance-attached marking
    alias :value :marking
    alias :m :marking
    alias :value= :marking=
    alias :m= :marking=

    attr_reader :upstream_arcs # Transitions that add/remove tokens from here.
    alias :upstream_transitions :upstream_arcs
    # Greek digamma ϝ alias is mnemonic for "function" in the spreadsheet sense,
    # that is, collection of transitions affecting this place.
    alias :ϝ :upstream_arcs

    attr_reader :downstream_arcs # Transitions that depend on this place.
    alias :downstream_transitions :downstream_arcs

    # #inspect
    def inspect
      nm, d, q = instance_description_strings
      "YPetri::Place[ #{USE_QUANTUM ? nm + d + q : nm + d} ]"
    end

    # #to_s
    def to_s
      n, m = name, marking
      "#{n.nil? ? 'Place' : n}[ #{m.nil? ? 'nil' : m} ]"
    end

    def initialize *aa; oo = aa.extract_options!
      # set domain and codomain of the place empty
      @upstream_arcs = []
      @downstream_arcs = []
      @quantum = oo.may_have( :quantum, syn!: :q ) || 1
      @default_marking = oo.may_have( :default_marking, syn!: [ :dflt_m, :m! ] )
      @marking = oo.may_have( :marking, syn!: :m ) || @default_marking
    end

    # Union of action and test arcs
    def arcs
      upstream_arcs | downstream_arcs
    end
    alias :connectivity :arcs

    # Precedents returns union of domains of the transitions associated
    # with the action arcs of this place.
    def precedents
      upstream_transitions
        .map( &:upstream_places )
        .reduce( [], :| )
    end
    alias :upstream_places :precedents

    # Dependents returns union of codomains of the transitions associated
    # with the test arcs of this place.
    def dependents
      downstream_transitions
        .map( &:downstream_places )
        .reduce( [], :| )
    end
    alias :downstream_places :dependents

    # Adding tokens
    def add( amount_of_tokens )
      @marking += amount_of_tokens
    end

    # Subtracting tokens
    def subtract( amount_of_tokens)
      @marking -= amount_of_tokens
    end

    # Resets marking back to default marking
    def reset_marking
      @marking = @default_marking
    end

    # Registering upstream transition
    def register_upstream_transition( transition )
      @upstream_arcs << transition
    end

    # Registering downstream transition
    def register_downstream_transition( transition )
      @downstream_arcs << transition
    end

    # Cocking-independent firing of upstream transition
    def fire_upstream!
      @upstream_arcs.each &:fire!
    end
    alias :fire! :fire_upstream!

    # Fires whole upstream portion of the net.
    def fire_upstream_recursively
      # LATER: so far, implemented without concerns about infinite loops
      # LATER: This as a global hash { place => fire_list }
      @upstream_arcs.each &:fire_upstream_recursively
    end
    alias :fire_upstream! :fire_upstream_recursively

    # Cock-independent firing of downstream transitions
    def fire_downstream!; @downstream_arcs.each &:fire! end

    # Fires whole downstream portion of the net.
    def fire_downstream_recursively
      # LATER: so far, implemented withoud concerns about infinite loops
      # LATER: This as a global hash { place => fire_list }
      @downstream_arcs.each &:fire_downstream_recursively
    end
    alias :fire_downstream! :fire_downstream_recursively

    private

    def instance_description_strings
      m, n, d, q = marking, name, default_marking, quantum
      mς = m.nil? ? 'nil' : m
      nmς = n.nil? ? "marking: #{mς}" : "#{n}: #{mς}"
      dς = d.nil? ? '' : ", default_marking: #{d}"
      qς = q.nil? ? '' : ", quantum: #{q}"
      return nmς, dς, qς
    end
  end # class Place
end # module YPetri
