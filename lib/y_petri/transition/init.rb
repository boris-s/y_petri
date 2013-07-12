# encoding: utf-8

# Constructor syntax aspect of a transition. Large part of the functionality
# of the Transition class is the convenient constructor syntax.
# 
class YPetri::Transition
  # Transition class represents many different kinds of Petri net transitions.
  # It makes the constructor syntax a bit more polymorphic. The type of the
  # transition to construct is mostly inferred from the constructor arguments.
  # 
  # Mandatorily, the constructor will always need a way to determine the domain
  # (upstream arcs) and codomain (downstream arcs) of the transition. Also, the
  # constructor must have a way to determine the transition's action. This is
  # best explained by examples -- let us have 3 places A, B, C, for whe we will
  # create different kinds of transitions:
  # 
  # 
  # ==== TS (timed stoichiometric)
  #
  # Rate closure and stoichiometry has to be supplied. Rate closure arity should
  # correspond to the domain size. Return arity should be 1 (to be multiplied by
  # the stoichiometry vector, as in all other stoichiometric transitions).
  #
  #   Transition.new stoichiometry: { A: -1, B: 1 },
  #                  rate: -> a { a * 0.5 }
  #                  
  #
  # ==== Ts (timed nonstoichiometric)
  # 
  # Rate closure has to be supplied, whose arity should match the domain, and
  # output arity codomain.
  # 
  # ==== tS (timeless stoichiometric)
  # 
  # Stoichiometry has to be supplied, action closure is optional. If supplied,
  # its return arity should be 1 (to be multiplied by the stoichiometry vector).
  # 
  # ==== ts transitions (timeless nonstoichiometric)
  # 
  # Action closure is expected with return arity equal to the codomain size:
  # 
  #   Transition.new upstream_arcs: [A, C], downstream_arcs: [A, B],
  #                  action_closure: proc { |m, x|
  #                                         if x > 0 then [-(m / 2), (m / 2)]
  #                                         else [1, 0] end
  #                                       }
  # 
  def initialize *args, &block
    check_in_arguments *args, &block # the big job
    extend timed? ? Timed : ( assignment? ? Assignment : OrdinaryTimeless )
    inform_upstream_places         # that they have been connected
    inform_downstream_places       # that they have been connected
    uncock                         # transitions initialize uncocked
  end

  private

  # Checking in the arguments supplied to #initialize looks like a big job.
  # I won't contest to that, but let us not, that it is basically nothing
  # else then defining the duck type of the input argument collection.
  # TypeError is therefore raised if invalid collection has been supplied.
  # 
  def check_in_arguments **nn, &block
    nn.update( action: block ) if block_given?
    nn.may_have :domain, syn!: [ :domain_arcs, :domain_places,
                                 :upstream, :upstream_arcs, :upstream_places ]
    nn.may_have :codomain, syn!: [ :codomain_arcs, :codomain_places,
                                   :downstream,
                                   :downstream_arcs, :downstream_places,
                                   :action_arcs ]
    nn.may_have :rate, syn!: [ :rate_closure, :propensity,
                               :propensity_closure ]
    nn.may_have :action, syn!: :action_closure
    nn.may_have :stoichiometry, syn!: [ :stoichio, :s ]
    nn.may_have :domain_guard
    nn.may_have :codomain_guard

    # If the rate was given, the transition is timed:
    @timed = nn.has? :rate

    # If stoichiometry was given, the transition is stoichiometric:
    @stoichiometric = nn.has? :stoichiometry

    # Downstream description involves the codomain, and the stochiometry
    # (for stoichiometric transitions only):
    if stoichiometric? then
      @codomain, @stoichiometry = __downstream_for_S__( **nn )
    else
      @codomain = __downstream_for_s__( **nn )
    end

    # Check in the domain first, :missing symbol may be returned if the user
    # has not supplied the domaing (the constructor will attempt to guessf it
    # automatically).
    @domain = __domain__( **nn )

    # Upstream description involves the domain and the rate/action closure.
    # Also, :missing domain is taken care of here.
    if timed? then
      @domain, @rate_closure, @functional = __upstream_for_T__( **nn )
    else
      @domain, @action_closure, @functional = __upstream_for_t__( **nn )
    end

    # Optional assignment action:
    @assignment_action = __assignment_action__( **nn )

    # Optional type guards for domain / codomain:
    @domain_guard, @codomain_guard = __guards__( **nn )
  end

  # Validates that the supplied collection consists only of places of
  # correct type. Second optional argument customizes the error message.
  # 
  def sanitize_place_collection place_collection, what_is_collection=nil
    c = what_is_collection ? what_is_collection.capitalize : "Collection"
    Array( place_collection ).map do |pl_id|
      begin
        place( pl_id )
      rescue NameError
        raise TypeError, "#{c} member #{pl_id} does not specify a valid place!"
      end
    end.aT what_is_collection, "not contain duplicate places" do |coll|
      coll == coll.uniq
    end
  end

  # Private method, part of #initialize argument checking-in.
  # 
  def __domain__( **nn )
    if nn.has? :domain then
      sanitize_place_collection( nn[:domain], "supplied domain" )
    else
      if stoichiometric? then
        # take arcs with non-positive coefficients
        Hash[ @codomain.zip @stoichiometry ].delete_if { |_, c| c > 0 }.keys
      else
        :missing # may mean empty domain, or domain == codomain
      end
    end
  end

  # Private method, part of the init process for timed transitions. Also takes
  # care for :missing domain, if :missing.
  # 
  def __upstream_for_T__( **nn )
    dom = domain # this method may modify domain
    fail ArgumentError, "Rate and action collision!" if nn.has? :action
    # Let's figure the rate closure now.
    λ = nn[:rate]
    if λ.is_a? Proc then
      if dom == :missing then
        dom = λ.arity == 0 ? [] : codomain
      else
        msg = "Rate closure arity (#{λ.arity}) > domain (#{dom.size})!"
        fail TypeError, msg if λ.arity.abs > dom.size
      end
    else # not a Proc, must guess user's intent
      λ = if stoichiometric? then # standard mass action
            msg = "With numeric rate, domain must not be given!"
            fail TypeError, msg if nn.has? :domain
            __standard_mass_action__( λ )
          else # constant closure
            msg = "With numeric rate and no stoichio., codomain size must be 1!"
            fail TypeError, msg unless codomain.size == 1
            lambda { λ }.tap do
              if dom == :missing then
                dom = [] # Missing domain is natural here
              else # but should it was supplied explicitly, it must be empty.
                msg = "Rate is a number, but domain is non-empty!"
                fail TypeError, msg unless domain.empty? if nn.has? :domain
              end
            end
          end
    end
    dom.aT_is_a Array
    λ.aT_is_a Proc
    return dom, λ, true # true here means "functional?", always true for T
  end

  # Private method, part of the init process when :rate is not given. Also
  # takes care for missing domain (@domain == :missing).
  # 
  def __upstream_for_t__( **nn )
    dom = domain                     # this method may modify domain
    funct = true                     # "functional?"
    # Was action given explicitly?
    if nn.has? :action then
      λ = nn[:action].aT_is_a Proc, "supplied action named argument"
      # Time to worry about the domain_missing, guess the user's intention:
      if dom == :missing then
        dom = λ.arity == 0 ? [] : codomain
      else
        msg = "Action closure arity (#{λ.arity}) > domain (#{dom.size})!"
        fail TypeError, msg if λ.arity.abs > dom.size
      end
    else # "functionless"
      funct = false
      λ = proc { 1 }
      msg = "Stoichiometry is compulsory, if no rate/action was supplied!"
      fail ArgumentError, msg unless stoichiometric?
      dom = [] # in any case, the domain is empty
    end
    return dom, λ, funct
  end
  
  # Default rate closure for SR transitions whose rate is hinted as a number.
  # 
  def __standard_mass_action__( num )
    # assume standard mass-action law
    nonpositive_coeffs = stoichiometry.select { |coeff| coeff <= 0 }
    # the closure takes markings of the domain as its arguments
    -> *markings do
      nonpositive_coeffs.size.times.reduce num do |acc, i|
        marking, coeff = markings[ i ], nonpositive_coeffs[ i ]
        # Stoichiometry coefficients equal to zero are taken to indicate
        # plain factors, assuming that if these places were not involved
        # in the transition at all, the user would not be mentioning them.
        case coeff
        when 0, -1 then marking * acc
        else marking ** -coeff end
      end
    end
  end

  # Private method, checking in downstream specification from the argument
  # field for stoichiometric transition.
  # 
  def __downstream_for_S__( **oo )
    codomain, stoichio =
      case oo[:stoichiometry]
      when Hash then
        # contains pairs { codomain place => stoichiometry coefficient }
        msg = "With hash-type stoichiometry, :codomain must not be given!"
        fail ArgumentError, msg if oo.has? :codomain
        oo[:stoichiometry].each_with_object [[], []] do |(cd_pl, coeff), memo|
          memo[0] << cd_pl
          memo[1] << coeff
        end
      else
        # array of stoichiometry coefficients
        msg = "With array-type stoichiometry, :codomain must be given!"
        fail ArgumentError unless oo.has? :codomain
        [ oo[:codomain], Array( oo[:stoichiometry] ) ]
      end
    # enforce that stoichiometry is a collection of numbers
    return sanitize_place_collection( codomain, "supplied codomain" ),
           stoichio.aT_all_numeric( "supplied stoichiometry" )
  end

  # Private method, checking in downstream specification from the argument
  # field for nonstoichiometric transition.
  # 
  def __downstream_for_s__( **oo )
    # codomain must be explicitly given - no way around it:
    fail ArgumentError, "For non-stoichiometric transitions, :codomain " +
      "argument is compulsory." unless oo.has? :codomain
    return sanitize_place_collection( oo[:codomain], "supplied codomain" )
  end

  # Private method, part of #initialize argument checking-in.
  # 
  def __assignment_action__( **oo )
    if oo.has? :assignment_action, syn!: [ :assignment, :assign, :A ] then
      if timed? then
        false.tap do
          msg = "Timed transitions may not have assignment action!"
          raise TypeError, msg if oo[:assignment_action]
        end
      else oo[:assignment_action] end # only timeless transitions are eligible
    else false end # the default value
  end

  # Private method, part of #initialize argument checking-in
  # 
  def __guards__( **oo )
    if oo.has? :domain_guard then
      oo[:domain_guard].aT_is_a Proc, "supplied domain guard"
    else
      place_guards = domain_places.map &:guard
      -> dm do # constructing the default domain guard
        fails = [domain, dm, place_guards].transpose.map { |pl, m, guard|
          [ pl, m, begin; guard.( m ); true; rescue YPetri::GuardError; false end ]
        }.reduce [] do |memo, triple| memo << triple unless triple[2] end
        # TODO: Watch "Exceptional Ruby" video by Avdi Grimm.
        unless fails.size == 0
          fail YPetri::GuardError, "Domain guard of #{self} rejects marking " +
            if fails.size == 1 then
              p, m, _ = fails[0]
              "#{m} of place #{p.name || p.object_id}!"
            else
              "of the following places: %s!" %
                Hash[ fails.map { |pl, m, _| [pl.name || pl.object_id, m] } ]
            end
        end
      end
    end
  end

  # Informs upstream places that they have been connected to this transition.
  # 
  def inform_upstream_places
    upstream_places.each { |p| p.send :register_downstream_transition, self }
  end

  # Informs downstream places that they are connected to this transition.
  # 
  def inform_downstream_places
    downstream_places.each { |p| p.send :register_upstream_transition, self }
  end
end # class YPetri::Transition
