#encoding: utf-8

module YPetri

  # This class represents Petri net places.
  # 
  class Place
    USE_QUANTUM = false
    include NameMagic

    attr_reader :quantum
    attr_accessor :default_marking
    attr_accessor :marking           # instance-attached marking
    alias :value :marking
    alias :m :marking

    # Alias for #marking=
    # 
    def value=( marking ); self.marking = marking end

    # Alias for #marking=
    # 
    def m=( marking ); self.marking = marking end
    
    # Transitions that can directly add/remove tokens from this place.
    # It is aliased as #upstream_transitions and #ϝ. (ϝ (Greek digamma) looks
    # like "function", which we know from spreadsheet software: A collection
    # of transitions directly affecting marking of this place.)
    # 
    attr_reader :upstream_arcs
    alias :upstream_transitions :upstream_arcs
    alias :ϝ :upstream_arcs

    # Transitions whose action directly depends on this place. Aliased
    # as #downstream_transitions.
    # 
    attr_reader :downstream_arcs
    alias :downstream_transitions :downstream_arcs

    # Named parameters supplied upon place initialization may include:
    # 
    # * :marking (alias :m)
    # * :default_marking (alias :dflt_m or :m!)
    # * :quantum (alias :q)
    # 
    # While 'marking' is a standard Petri net concept, and default marking
    # is self-explanatory, place quantum is the concept by which YPetri
    # reconciles with letter H in the abbreviation HFPN. YPetri places are
    # always considered discrete, and it is true insomuch, as their marking
    # is represented by a finite-digit number. The place quantum feature is
    # not supported yet, but in future, it should enable smooth transition
    # between continuous and stochastic modes of simulation.
    # 
    def initialize *aa; oo = aa.extract_options!
      # set domain and codomain of the place empty
      @upstream_arcs = []
      @downstream_arcs = []
      @quantum = oo.may_have( :quantum, syn!: :q ) || 1
      @default_marking = oo.may_have( :default_marking, syn!: [ :dflt_m, :m! ] )
      @marking = oo.may_have( :marking, syn!: :m ) || @default_marking
    end

    # Returns an array of all the transitions connected to the place.
    # 
    def arcs
      upstream_arcs | downstream_arcs
    end
    alias :connectivity :arcs

    # Returns the union of domains of the transitions associated
    # with the upstream arcs of this place.
    # 
    def precedents
      upstream_transitions
        .map( &:upstream_places )
        .reduce( [], :| )
    end
    alias :upstream_places :precedents

    # Returns the union of codomains of the transitions associated
    # with the downstream arcs originating from this place.
    # 
    def dependents
      downstream_transitions
        .map( &:downstream_places )
        .reduce( [], :| )
    end
    alias :downstream_places :dependents

    # Adds tokens to the place.
    # 
    def add( amount_of_tokens )
      @marking += amount_of_tokens
    end

    # Subtracts tokens from the place.
    # 
    def subtract( amount_of_tokens)
      @marking -= amount_of_tokens
    end

    # Resets place marking back to its default marking.
    # 
    def reset_marking
      @marking = @default_marking
    end

    # Firing of upstream transitions regardless of cocking. (To #fire
    # transitions, they have to be cocked with #cock method; the firing
    # methods with exclamation marks disregard cocking.)
    # 
    def fire_upstream!
      @upstream_arcs.each &:fire!
    end
    alias :fire! :fire_upstream!

    # Fires whole upstream portion of the net.
    # 
    def fire_upstream_recursively
      # LATER: so far, implemented without concerns about infinite loops
      # LATER: This as a global hash { place => fire_list }
      @upstream_arcs.each &:fire_upstream_recursively
    end
    alias :fire_upstream! :fire_upstream_recursively

    # Firing of downstream transitions regardless of cocking. (To #fire
    # transitions, they have to be cocked with #cock method; the firing
    # methods with exclamation marks disregard cocking.)
    # 
    def fire_downstream!
      @downstream_arcs.each &:fire!
    end

    # Fires whole downstream portion of the net.
    # 
    def fire_downstream_recursively
      # LATER: so far, implemented withoud concerns about infinite loops
      # LATER: This as a global hash { place => fire_list }
      @downstream_arcs.each &:fire_downstream_recursively
    end
    alias :fire_downstream! :fire_downstream_recursively
    
    def inspect                      # :nodoc:
      nm, d, q = instance_description_strings
      "YPetri::Place[ #{USE_QUANTUM ? nm + d + q : nm + d} ]"
    end

    def to_s                         # :nodoc:
      n, m = name, marking
      "#{n.nil? ? 'Place' : n}[ #{m.nil? ? 'nil' : m} ]"
    end

    private

    # Makes the place notice an upstream transition;
    # to be called from the connecting transitions.
    def register_upstream_transition( transition )
      @upstream_arcs << transition
    end

    # Makes the place notice a downstream transition;
    # to be called from the connecting transitions.
    def register_downstream_transition( transition )
      @downstream_arcs << transition
    end

    def instance_description_strings
      m, n, d, q = marking, name, default_marking, quantum
      mς = m.nil? ? 'nil' : m
      nmς = n.nil? ? "marking: #{mς}" : "#{n}: #{mς}"
      dς = d.nil? ? '' : ", default_marking: #{d}"
      qς = q.nil? ? '' : ", quantum: #{q}"
      return nmς, dς, qς
    end

    # Place, Transition, Net class
    # 
    def Place; ::YPetri::Place end
    def Transition; ::YPetri::Transition end
    def Net; ::YPetri::Net end

    # Instance identification methods.
    # 
    def place( which ); Place().instance( which ) end
    def transition( which ); Transition().instance( which ) end
    def net( which ); Net().instance( which ) end
  end # class Place
end # module YPetri
