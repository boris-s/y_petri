# -*- coding: utf-8 -*-

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
  # ==== ts transitions (timeless nonstoichiometric)
  # Action closure is expected with return arity equal to the codomain size:
  # 
  #   Transition.new upstream_arcs: [A, C], downstream_arcs: [A, B],
  #                  action_closure: proc { |m, x|
  #                                         if x > 0 then [-(m / 2), (m / 2)]
  #                                         else [1, 0] end
  #                                       }
  # 
  # (If C is positive, half of A's marking is moved to B, otherwise A is
  # incremented by 1.)
  #
  # ==== tS transitions (timeless stoichiometric)
  # Stochiometry has to be supplied, action closure is optional. If supplied,
  # its return arity should be 1 (to be multiplied by the stochiometry vector).
  #
  # If no action closure is given, a _functionless_ transition will be
  # constructed, with action closure == 1 * stoichiometry vector.
  #
  # ==== Tsr transitions (timed rateless nonstoichiometric)
  # Action closure has to be supplied, whose first argument is Δt, and the
  # remaining ones correspond to the domain size. Return arity of this closure
  # should, in turn, correspond to the codomain size.
  # 
  # ==== TSr transitions (timed rateless stoichiometric)
  # Action closure has to be supplied, whose first argument is Δt, and the
  # remaining ones correspond to the domain size. Return arity of this closure
  # should be 1 (to be multiplied by the stoichiometry vector).
  # 
  # ==== sR transitions (nonstoichiometric transitions with rate)
  # Rate closure has to be supplied, whose arity should correspond to the domain
  # size (Δt argument is not needed). Return arity of this should, in turn,
  # correspond to the codomain size -- it represents this transition's
  # contribution to the rate of change of marking of the codomain places.
  # 
  # ==== SR transitions (stoichiometric transitions with rate)
  #
  # Rate closure and stoichiometry has to be supplied. Rate closure arity should
  # correspond to the domain size. Return arity should be 1 (to be multiplied by
  # the stoichiometry vector, as in all other stoichiometric transitions).
  #
  #   Transition.new stoichiometry: { A: -1, B: 1 },
  #                  rate: λ { |a| a * 0.5 }
  #       
  def initialize *args
    check_in_arguments *args       # the big work of checking in args
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
  def check_in_arguments *aa, **oo, &block
    oo.may_have :stoichiometry, syn!: [ :stoichio, :s ]
    oo.may_have :codomain, syn!: [ :codomain_arcs, :codomain_places,
                                   :downstream,
                                   :downstream_arcs, :downstream_places,
                                   :action_arcs ]
    oo.may_have :domain, syn!: [ :domain_arcs, :domain_places,
                                 :upstream, :upstream_arcs, :upstream_places ]
    oo.may_have :rate, syn!: [ :rate_closure, :propensity,
                               :propensity_closure ]
    oo.may_have :action, syn!: :action_closure
    oo.may_have :timed
    oo.may_have :domain_guard
    oo.may_have :codomain_guard

    @has_rate = oo.has? :rate      # was the rate was given?

    # is the transition stoichiometric (S) or nonstoichiometric (s)?
    @stoichiometric = oo.has? :stoichiometry

    # downstream description arguments: codomain, stoichiometry (if S)
    if stoichiometric? then
      @codomain, @stoichiometry = check_in_downstream_description_for_S( oo )
    else # s transitions have no stoichiometry
      @codomain = check_in_downstream_description_for_s( oo )
    end

    # check in domain first, :missing symbol may appear
    @domain = check_in_domain( oo )

    # upstream description arguments; also takes care of :missing domain
    if has_rate? then
      @domain, @rate_closure, @timed, @functional =
        check_in_upstream_description_for_R( oo, &block )
    else
      @domain, @action_closure, @timed, @functional =
        check_in_upstream_description_for_r( oo, &block )
    end

    # optional assignment action:
    @assignment_action = check_in_assignment_action( oo )

    # optional type guards for domain / codomain:
    @domain_guard, @codomain_guard = check_in_guards( oo )
  end # def check_in_arguments
    
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
  def check_in_domain( oo )
    if oo.has? :domain then
      sanitize_place_collection( oo[:domain], "supplied domain" )
    else
      if stoichiometric? then
        # take arcs with non-positive stoichiometry coefficients
        Hash[ [ @codomain, @stoichiometry ].transpose ]
          .delete_if{ |_place, coeff| coeff > 0 }.keys
      else
        :missing
        # Barring the caller's error, missing domain can mean:
        # 1. empty domain
        # 2. domain == codomain
        # This will be figured later by rate/action closure arity
      end
    end
  end

  # Private method, part of the init process when :rate is given. Also takes
  # care for missing domain (@domain == :missing).
  # 
  def check_in_upstream_description_for_R( oo, &block )
    _domain = domain # this method may modify domain
    fail ArgumentError, "Rate/propensity and action may not be both given!" if
      oo.has? :action # check against colliding :action named argument
    fail ArgumentError, "If block is given, rate must not be given!" if block
    # Let's figure the rate closure now. (Block is never used.)
    rate_λ = case ra = oo[:rate]
             when Proc then # We received the closure directly,
               ra.tap do |λ| # but we've to be concerned about missing domain.
                 if domain == :missing then # we've to figure user's intent
                   _domain = if λ.arity == 0 then [] # user meant empty domain
                             else codomain end # user meant domain == codomain
                 else # domain not missing
                   fail TypeError, "Rate closure arity (#{λ.arity}) > " +
                     "domain (#{domain.size})!" if λ.arity.abs > domain.size
                 end
               end
             else # We received something else, must guess user's intent.
               if stoichiometric? then # user's intent was mass action
                 fail TypeError, "When a number is supplied as rate, " +
                   "domain must not be given!" if oo.has? :domain
                 construct_standard_mass_action( ra )
               else # user's intent was constant closure
                 fail TypeError, "When rate is a number and stoichiometry " +
                   "is not given, codomain size must be 1!" unless
                   codomain.size == 1
                 # Missing domain is OK here,
                 _domain = [] if domain == :missing
                 # but if it was supplied explicitly, it must be empty.
                 fail TypeError, "Rate is a number, but non-empty domain " +
                   "was supplied!" unless domain.empty? if oo.has?( :domain )
                 -> { ra }
               end
             end
    # R transitions are implicitly timed
    _timed = true
    # check against colliding :timed argument
    oo[:timed].tE :timed, "not be false if rate given" if oo.has? :timed
    # R transitions are implicitly functional
    _functional = true
    return _domain, rate_λ, _timed, _functional
  end

  # Private method, part of the init process when :rate is not given. Also
  # takes care for missing domain (@domain == :missing).
  # 
  def check_in_upstream_description_for_r( oo, &block )
    _domain = domain               # this method may modify domain
    _functional = true
    # Was action closure was given explicitly?
    if oo.has? :action then
      fail ArgumentError, "If block is given, rate must not be given!" if block
      action_λ = oo[:action].aT_is_a Proc, "supplied action named argument"
      if oo.has? :timed then
        _timed = oo[:timed]
        # Time to worry about the domain_missing
        if domain == :missing then # figure user's intent from closure arity
          _domain = if action_λ.arity == ( _timed ? 1 : 0 ) then
                      [] # user meant empty domain
                    else
                      codomain # user meant domain same as codomain
                    end
        else # domain not missing
          fail TypeError, "Rate closure arity (#{rate_arg.arity}) > domain " +
            "size (#{domain.size})!" if action_λ.arity.abs > domain.size
        end
      else # :timed argument not supplied
        if domain == :missing then
          # If no domain was supplied, there is no way to reasonably figure
          # out the user's intent, except when arity is 0:
          _domain = case action_λ.arity
                    when 0 then
                      _timed = false
                      [] # empty domain is implied
                    else # no deduction of user intent possible
                      fail ArgumentError, "Too much ambiguity: Rateless " +
                        "transition with neither domain nor timedness given."
                    end
        else # domain not missing
          # Even if the user did not bother to inform us explicitly about
          # timedness, we can use closure arity as a clue. If it equals the
          # domain size, leaving no room for Δtime argument, the user intent
          # was to create timeless transition. If it equals domain size + 1,
          # theu user intended to create a timed transition.
          _timed = case action_λ.arity
                   when domain.size then false
                   when domain.size + 1 then true
                   else # no deduction of user intent possible
                     fail ArgumentError, "Timedness was not specified, and " +
                       "action closure arity (#{action_λ.arity}) does not " +
                       "give a clear hint on it!"
                   end
        end
      end
    else # rateless cases with no action closure specified
      # Consume block, if given:
      check_in_upstream_for_r oo.update( action: block ) if block
      # If there is really really no closure, an assumption must be made taken
      # as for the transition's action, in particular, -> { 1 } closure:
      action_λ = -> { 1 }
      # The transition is then required to be stoichiometric and timeless.
      # Domain will be required empty.
      fail ArgumentError, "Stoichiometry is compulsory, if no rate/action " +
        "was supplied." unless stoichiometric?
      # With this, we can drop worries about missing domain.
      fail ArgumentError, "When no rate/propensity or action is supplied, " +
        "the transition cannot be timed." if oo[:timed] if oo.has? :timed
      _timed = false
      _domain = []
      _functional = false # the transition is considered functionless
    end
    return _domain, action_λ, _timed, _functional
  end
  
  # Default rate closure for SR transitions whose rate is hinted as a number.
  # 
  def construct_standard_mass_action( num )
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
  def check_in_downstream_description_for_S( oo )
    codomain, stoichio =
      case oo[:stoichiometry]
      when Hash then
        # contains pairs { codomain place => stoichiometry coefficient }
        fail ArgumentError, "With hash-type stoichiometry, :codomain " +
          "argument must not be given!" if oo.has? :codomain
        oo[:stoichiometry].each_with_object [[], []] do |(cd_pl, coeff), memo|
        memo[0] << cd_pl
        memo[1] << coeff
      end
      else
        # array of stoichiometry coefficients
        fail ArgumentError, "With array-type stoichiometry, :codomain " +
          "argument must be given!" unless oo.has? :codomain
        [ oo[:codomain], Array( oo[:stoichiometry] ) ]
      end
    # enforce that stoichiometry is a collection of numbers
    return sanitize_place_collection( codomain, "supplied codomain" ),
           stoichio.aT_all_numeric( "supplied stoichiometry" )
  end

  # Private method, checking in downstream specification from the argument
  # field for nonstoichiometric transition.
  # 
  def check_in_downstream_description_for_s( oo )
    # codomain must be explicitly given - no way around it:
    fail ArgumentError, "For non-stoichiometric transitions, :codomain " +
      "argument is compulsory." unless oo.has? :codomain
    return sanitize_place_collection( oo[:codomain], "supplied codomain" )
  end

  # Private method, part of #initialize argument checking-in.
  # 
  def check_in_assignment_action( oo )
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
  def check_in_guards( oo )
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
