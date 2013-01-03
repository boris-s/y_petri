#encoding: utf-8

# Now is a good time to talk about transition classification:
#
# STOICHIOMETRIC / NON-STOICHIOMETRIC
# I. For stoichiometric transitions:
#    1. Rate vector is computed as rate * stoichiometry vector, or
#    2. Δ vector is computed a action * stoichiometry vector.
# II. For non-stoichiometric transitions:
#    1. Rate vector is obtained as the rate closure result, or
#    2. action vector is obtained as the action closure result.
# 
# Conclusion: stoichiometricity distinguishes *need to multiply the
# rate/action closure result by stoichiometry*.
#
# HAVING / NOT HAVING RATE
# I. For transitions with rate, the closure result has to be
# multiplied by the time step duration (delta_t) to get action.
# II. For rateless transitions, the closure result is used as is.
#
# Conclusion: has_rate? distinguishes *need to multiply the closure
# result by delta time* - differentiability of action by time.
#
# TIMED / TIMELESS
# I. For timed transitions, action is time-dependent. Transitions with
# rate are thus always timed. In rateless transitions, timedness means
# that the action closure expects time step length (delta_t) as its first
# argument - its arity is thus codomain size + 1. 
# II. For timeless transitions, action is time-independent. Timeless
# transitions are necessarily also rateless. Arity of the action closure
# is expected to match the domain size.
# 
# Conclusion: Transitions with rate are always timed. In rateless
# transitions, timedness distinguishes the need to supply time step
# duration as the first argument to the action closure.
#
# ASSIGNMENT TRANSITIONS
# Named argument :assignment_action set to true indicates that the
# transitions acts by replacing the object stored as place marking by
# the object supplied by the transition. For numeric types, same
# effect can be achieved by subtracting the old number from the place
# and subsequently adding the new value to it.
#
module YPetri

  # Represents a Petri net transition. YPetri transitions come in 6
  # basic types
  #
  # === Basic transition types
  # 
  # * <b>ts</b> – timeless nonstoichiometric
  # * <b>tS</b> – timeless stoichiometric
  # * <b>Tsr</b> – timed rateless nonstoichiometric
  # * <b>TSr</b> – timed rateless stoichiometric
  # * <b>sR</b> – nonstoichiometric with rate
  # * <b>SR</b> – stoichiometric with rate
  #
  # These 6 kinds of YPetri transitions correspond to the vertices
  # of a cube with 3 dimensions:
  # 
  # - stoichiometric (S) / nonstoichiometric (s)
  # - timed (T) / timeless (t)
  # - having rate (R) / not having rate (r)
  # 
  # Since transitions with rate are always timed, and vice-versa, timeless
  # transitions cannot have rate, there are only 6 permissible combinations,
  # mentioned above.
  #
  # === Domain and codomin
  #
  # Each transition has a domain, or 'upstream places': A collection of places
  # whose marking directly affects the transition's operation. Also, each
  # transition has a codomain, or 'downstream places': A collection of places,
  # whose marking is directly affected by the transition's operation.
  #
  # === Action and action vector
  #
  # Regardless of the type, every transition has <em>action</em>:
  # A prescription of how the transition changes the marking of its codomain
  # when it fires. With respect to the transition's codomain, we can also
  # talk about <em>action vector</em>. For non-stoichiometric transitions,
  # the action vector is directly the output of the action closure or rate
  # closure multiplied by Δtime, while for stoichiometric transitions, this
  # needs to be additionaly multiplied by the transitions stoichiometric
  # vector. Now we are finally equipped to talk about the exact meaning of
  # 3 basic transition properties.
  #
  # === Meaning of the 3 basic transition properties
  #
  # ==== Stoichiometric / non-stoichiometric
  # * For stoichiometric transitions:
  #    [Rate vector] is computed as rate * stoichiometry vector, or
  #    [Δ vector] is computed a action * stoichiometry vector
  # * For non-stoichiometric transitions:
  #    [Rate vector] is obtained as the rate closure result, or
  #    [action vector] is obtained as the action closure result.
  # 
  # Conclusion: stoichiometricity distinguishes <b>need to multiply the
  # rate/action closure result by stoichiometry</b>.
  #
  # ==== Having / not having rate
  # * For transitions with rate, the closure result has to be
  # multiplied by the time step duration (Δt) to get the action.
  # * For rateless transitions, the closure result is used as is.
  #
  # Conclusion: has_rate? distinguishes <b>the need to multiply the closure
  # result by delta time</b> - differentiability of action by time.
  #
  # ==== Timed / Timeless
  # * For timed transitions, action is time-dependent. Transitions with
  # rate are thus always timed. In rateless transitions, timedness means
  # that the action closure expects time step length (delta_t) as its first
  # argument - its arity is thus codomain size + 1. 
  # * For timeless transitions, action is time-independent. Timeless
  # transitions are necessarily also rateless. Arity of the action closure
  # is expected to match the domain size.
  # 
  # Conclusion: Transitions with rate are always timed. In rateless
  # transitions, timedness distinguishes <b>the need to supply time step
  # duration as the first argument to the action closure</b>.
  #
  # === Other transition types
  #
  # ==== Assignment transitions
  # Named argument :assignment_action set to true indicates that the
  # transitions acts by replacing the object stored as place marking by
  # the object supplied by the transition. (Same as in with spreadsheet
  # functions.) For numeric types, same effect can be achieved by subtracting
  # the old number from the place and subsequently adding the new value to it.
  #
  # ==== Functional / Functionless transitions
  # Original Petri net definition does not speak about transition "functions",
  # but it more or less assumes timeless action according to the stoichiometry.
  # So in YPetri, stoichiometric transitions with no action / rate closure
  # specified become functionless transitions as meant by Carl Adam Petri.
  # 
  class Transition
    include NameMagic

    BASIC_TRANSITION_TYPES = {
      "ts" => "timeless nonstoichiometric transition",
      "tS" => "timeless stoichiometric transition",
      "Tsr" => "timed rateless nonstoichiometric transition",
      "TSr" => "timed rateless stoichiometric transition",
      "sR" => "nonstoichiometric transition with rate",
      "SR" => "stoichiometric transition with rate"
    }

    # Domain, or 'upstream arcs', is a collection of places, whose marking
    # directly affects the transition's action.
    # 
    attr_reader :domain
    alias :domain_arcs :domain
    alias :domain_places :domain
    alias :upstream :domain
    alias :upstream_arcs :domain
    alias :upstream_places :domain

    # Names of upstream places.
    # 
    def domain_pp; domain.map &:name end
    alias :upstream_pp :domain_pp

    # Names of upstream places as symbols.
    # 
    def domain_pp_sym; domain_pp.map &:to_sym end
    alias :upstream_pp_sym :domain_pp_sym
    alias :domain_ppß :domain_pp_sym
    alias :ustream_ppß :domain_pp_sym

    # Codomain, 'downstream arcs', or 'action arcs' is a collection of places,
    # whose marking is directly changed by firing the trinsition.
    # 
    attr_reader :codomain
    alias :codomain_arcs :codomain
    alias :codomain_places :codomain
    alias :downstream :codomain
    alias :downstream_arcs :codomain
    alias :downstream_places :codomain
    alias :action_arcs :codomain

    # Names of downstream places.
    # 
    def codomain_pp; codomain.map &:name end
    alias :downstream_pp :codomain_pp

    # Names of downstream places as symbols.
    # 
    def codomain_pp_sym; codomain_pp.map &:to_sym end
    alias :downstream_pp_sym :codomain_pp_sym
    alias :codomain_ppß :codomain_pp_sym
    alias :downstream_ppß :codomain_pp_sym

    # Returns the union of action arcs and test arcs.
    # 
    def arcs; domain | codomain end
    alias :connectivity :arcs

    # Returns connectivity as names.
    # 
    def cc; connectivity.map &:name end

    # Returns connectivity as name symbols.
    # 
    def cc_sym; cc.map &:to_sym end
    alias :ccß :cc_sym

    # Is the transition stoichiometric?
    # 
    def stoichiometric?; @stoichiometric end
    alias :s? :stoichiometric?

    # Is the transition nonstoichiometric? (Opposite of #stoichiometric?)
    # 
    def nonstoichiometric?; not stoichiometric? end

    # Stoichiometry (implies that the transition is stoichiometric).
    # 
    attr_reader :stoichiometry

    # Stoichiometry as a hash of pairs:
    # { codomain_place_instance => stoichiometric_coefficient }
    # 
    def stoichio; Hash[ codomain.zip( @stoichiometry ) ] end

    # Stoichiometry as a hash of pairs:
    # { codomain_place_name_symbol => stoichiometric_coefficient }
    # 
    def s; stoichio.with_keys { |k| k.name.to_sym } end

    # Does the transition have rate?
    # 
    def has_rate?; @has_rate end

    # Is the transition rateless?
    # 
    def rateless?; not has_rate? end

    # The term 'flux' (meaning flow) is associated with continuous transitions,
    # while term 'propensity' is used with discrete stochastic transitions.
    # By the design of YPetri, distinguishing between discrete and continuous
    # computation is the responsibility of the simulation method, considering
    # current marking of the transition's connectivity and quanta of its
    # codomain. To emphasize unity of 'flux' and 'propensity', term 'rate' is
    # used to represent both of them. Rate closure input arguments must
    # correspond to the domain places.
    # 
    attr_reader :rate_closure
    alias :rate :rate_closure
    alias :flux_closure :rate_closure
    alias :flux :rate_closure
    alias :propensity_closure :rate_closure
    alias :propensity :rate_closure

    # For rateless transition, action closure must be present. Action closure
    # input arguments must correspond to the domain places, and for timed
    # transitions, the first argument of the action closure must be Δtime.
    # 
    attr_reader :action_closure
    alias :action :action_closure

    # Does the transition's action depend on delta time?
    # 
    def timed?; @timed end

    # Is the transition timeless? (Opposite of #timed?)
    # 
    def timeless?; not timed? end

    # Is the transition functional?
    # Explanation: If rate or action closure is supplied, a transition is always
    # considered 'functional'. Otherwise, it is considered not 'functional'.
    # Note that even transitions that are not functional still have standard
    # action acc. to Petri's definition. Also note that a timed transition is
    # necessarily functional.
    # 
    def functional?; @functional end

    # Opposite of #functional?
    # 
    def functionless?; not functional? end

    # Reports transition membership in one of 6 basic types of YPetri transitions:
    # 1. ts ..... timeless nonstoichiometric
    # 2. tS ..... timeless stoichiometric
    # 3. Tsr .... timed rateless nonstoichiometric
    # 4. TSr .... timed rateless stoichiometric
    # 5. sR ..... nonstoichiometric with rate
    # 6. SR ..... stoichiometric with rate
    # 
    def basic_type
      if has_rate? then stoichiometric? ? "SR" : "sR"
      elsif timed? then stoichiometric? ? "TSr" : "Tsr"
      else stoichiometric? ? "tS" : "ts" end
    end

    # Is it an assignment transition?
    # 
    # A transition can be specified to have 'assignment action', in which case
    # it completely replaces codomain marking with the objects resulting from
    # the transition's action. Note that for numeric marking, specifying
    # assignment action is a matter of convenience, not necessity, as it can
    # be emulated by fully subtracting the present codomain values and adding
    # the numbers computed by the transition to them. Assignment action flag
    # is a matter of necessity only when codomain marking involves objects
    # not supporting subtraction/addition (which is out of the scope of Petri's
    # original specification anyway.)
    # 
    def assignment_action?; @assignment_action end
    alias :assignment? :assignment_action?

    # Is the transition cocked?
    # 
    # The transition has to be cocked before #fire method can be called
    # successfully. (Can be overriden using #fire! method.)
    # 
    def cocked?; @cocked end

    # Opposite of #cocked?
    # 
    def uncocked?; not cocked? end

    # As you could have noted in the introduction, Transition class encompasses
    # all different kinds of Petri net transitions. This is considered a good
    # design pattern for cases like this, but it makes the transition class and
    # its constructor look a bit complicated. Should you feel that way, please
    # remember that you only learn one constructor, but can create many kinds
    # of transition – the computer is doing a lot of work behind the scenes for
    # you. The type of a transition created depends on the qualities of supplied
    # arguments. However, you can also explicitly specify what kind of
    # transition do you want, to exclude any ambiguity.
    # 
    # Whatever arguments you supply, the constructor will always need a way to
    # determine domain (upstream arcs) and codomain (downstream arcs) of your
    # transitions, implicitly or explicitly. Secondly, the constructor must
    # have a way to determine the transition's action, although there is more
    # than one way of doing so. So enough talking and onto the examples. We
    # will imagine having 3 places A, B, C, for which we will create various
    # transitions:
    # 
    # ==== Timeless nonstoichiometric (ts) transitions
    # Action closure has to be supplied, whose return arity correspons to
    # the codomain size.
    # <tt>
    # Transition.new upstream_arcs: [A, C], downstream_arcs: [A, B],
    #                action_closure: proc { |m, x|
    #                                       if x > 0 then [-(m / 2), (m / 2)]
    #                                       else [1, 0] end }
    # </tt>
    # (This represents a transition connected by arcs to places A, B, C, whose
    # operation depends on C in such way, that if C.marking is positive,
    # then half of the marking of A is shifted to B, while if C.marking is
    # nonpositive, 1 is added to A.)
    #
    # ==== Timeless stoichiometric (tS) transitions
    # Stochiometry has to be supplied, with optional action closure.
    # Action closure return arity should be 1 (its result will be multiplied
    # by the stoichiometry vector).
    #
    # If no action closure is given, a <em>functionless</em> transition will
    # be created, whose action closure will be by default 1 * stoichiometry
    # vector.
    #
    # ==== Timed rateless nonstoichiometric (Tsr) transitions
    # Action closure has to be supplied, whose first argument is Δt, and the
    # remaining arguments correspond to the domain size. Return arity of this
    # closure should correspond to the codomain size.
    # 
    # ==== Timed rateless stoichiometric (TSr) transitions
    # Action closure has to be supplied, whose first argument is Δt, and the
    # remaining arguments correspond to the domain size. Return arity of this
    # closure should be 1 (to be multiplied by the stoichiometry vector).
    # 
    # ==== Nonstoichiometric transitions with rate (sR)
    # Rate closure has to be supplied, whose arity should correspond to the
    # domain size (Δt argument is not needed). Return arity of this closure
    # should correspond to the codomain size and represents rate of change
    # contribution for marking of the codomain places.
    # 
    # ==== Stoichiometric transitions with rate (SR)
    #
    # Rate closure and stoichiometry has to be supplied, whose arity should
    # correspond to the domain size. Return arity of this closure should be 1
    # (to be multiplied by the stoichiometry vector, as in all stoichiometric
    # transitions).
    #
    # <tt>Transition( stoichiometry: { A: -1, B: 1 },
    #                 rate: λ { |a| a * 0.5 } )
    #       
    def initialize *args
      # do the big work of checking in the arguments
      check_in_arguments *args
      # Inform the relevant places that they have been connected:
      upstream.each{ |place| place.send :register_downstream_transition, self }
      downstream.each{ |place| place.send :register_upstream_transition, self }
      # transitions initialize uncocked:
      @cocked = false
    end

    # Marking of the domain places.
    # 
    def domain_marking
      domain.map &:marking
    end

    # Marking of the codomain places.
    # 
    def codomain_marking
      codomain.map &:marking
    end

    # Result of the transition's "function", regardless of the #enabled? status.
    # 
    def action( Δt=nil )
      raise AErr, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      # the code here looks awkward, because I was trying to speed it up
      if has_rate? then
        if stoichiometric? then
          rate = rate_closure.( *domain_marking )
          stoichiometry.map{ |coeff| rate * coeff * Δt }
        else # assuming correct return value arity from the rate closure:
          rate_closure.( *domain_marking ).map{ |e| component * Δt }
        end
      else # rateless
        if timed? then
          if stoichiometric? then
            rslt = action_closure.( Δt, *domain_marking )
            stoichiometry.map{ |coeff| rslt * coeff }
          else
            action_closure.( Δt, *domain_marking ) # caveat result arity!
          end
        else # timeless
          if stoichiometric? then
            rslt = action_closure.( *domain_marking )
            stoichiometry.map{ |coeff| rslt * coeff }
          else
            action_closure.( *domain_marking ) # caveat result arity!
          end
        end
      end
    end # action

    # Zero action
    # 
    def zero_action
      codomain.map { 0 }
    end

    # Changes to the marking of codomain, as they would happen if #fire! was
    # called right now (ie. honoring #enabled?, but not #cocked? status.
    # 
    def action_after_feasibility_check( Δt=nil )
      raise AErr, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      act = Array( action Δt )
      # Assignment actions are always feasible - no need to check:
      return act if assignment?
      # check if the marking after the action would still be positive
      enabled = codomain
        .zip( act )
        .all?{ |place, change| place.marking.to_f >= -change.to_f }
      if enabled then act else
        raise "firing of #{self}#{ Δt ? ' with Δtime %s' % Δt : '' } " +
          "would result in negative marking"
        zero_action
      end
      # LATER: This use of #zip here should be avoided for speed
    end

    # Allows #fire method to succeed. (#fire! disregards cocking.)
    # 
    def cock; @cocked = true end
    alias :cock! :cock

    # Uncocks a cocked transition without firing it.
    # 
    def uncock; @cocked = false end
    alias :uncock! :uncock

    # If #fire method of a transition applies its action (token adding/taking)
    # on its domain, depending on codomain marking. Time step is expected as
    # argument if the transition is timed. Only works if the transition has
    # been cocked and causes the transition to uncock.
    # 
    def fire( Δt=nil )
      raise AErr, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      return false unless cocked?
      uncock
      fire! Δt
      return true
    end

    # #fire! (with bang) fires the transition regardless of cocked status.
    # 
    def fire!( Δt=nil )
      raise AErr, "Δtime required for timed transitions!" if timed? && Δt.nil?
      if assignment_action? then
        act = Array action( Δt )
        codomain.each_with_index do |place, i|
          place.marking = act[i]
        end
      else
        act = action_after_feasibility_check( Δt )
        codomain.each_with_index do |place, i|
          place.add act[i]
        end
      end
      return nil
    end

    # Sanity of execution is ensured by Petri's notion of transitions being
    # "enabled" if and only if the intended action can immediately take
    # place without getting places into forbidden state (negative marking).
    # 
    def enabled?( Δt=nil )
      raise AErr, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      codomain
        .zip( action Δt )
        .all? { |place, change| place.marking.to_f >= -change.to_f }
    end

    # Recursive firing of the upstream net portion (honors #cocked?).
    # 
    def fire_upstream_recursively
      return false unless cocked?
      uncock
      upstream_places.each &:fire_upstream_recursively
      fire!
      return true
    end

    # Recursive firing of the downstream net portion (honors #cocked?).
    # 
    def fire_downstream_recursively
      return false unless cocked?
      uncock
      fire!
      downstream_places.each &:fire_downstream_recursively
      return true
    end

    # def lock
    #   # LATER
    # end
    # alias :disable! :force_disabled

    # def unlock
    #   # LATER
    # end
    # alias :undisable! :remove_force_disabled

    # def force_enabled!( boolean )
    #   # true - the transition is always regarded as enabled
    #   # false - the status is removed
    #   # LATER
    # end

    # def clamp
    #   # LATER
    # end

    # def remove_clamp
    #   # LATER
    # end

    # def reset!
    #   uncock
    #   remove_force_disabled
    #   remove_force_enabled
    #   remove_clamp
    #   return self
    # end

    # Inspect string for a transition.
    # 
    def inspect
      to_s
    end

    # Conversion to a string.
    # 
    def to_s
      "#<Transition: %s >" %
        "#{name.nil? ? '' : '%s ' % name }(#{basic_type}%s)%s" %
        [ "#{assignment_action? ? ' Assign.' : ''}",
          "#{name.nil? ? ' id:%s' % object_id : ''}" ]
    end

    private

    # **********************************************************************
    # ARGUMENT CHECK-IN UPON INITIALIZATION
    # **********************************************************************

    # Checking in the arguments supplied to #initialize looks like a big job.
    # I won't contest to that, but let us not, that it is basically nothing
    # else then defining the duck type of the input argument collection.
    # TypeError is therefore raised if invalid collection has been supplied.
    # 
    def check_in_arguments *args
      oo = args.extract_options!
      oo.may_have :stoichiometry, syn!: [ :stoichio,
                                          :s ]
      oo.may_have :codomain, syn!: [ :codomain_arcs,
                                     :codomain_places,
                                     :downstream,
                                     :downstream_arcs,
                                     :downstream_places,
                                     :action_arcs ]
      oo.may_have :domain, syn!: [ :domain_arcs,
                                   :domain_places,
                                   :upstream,
                                   :upstream_arcs,
                                   :upstream_places ]
      oo.may_have :rate, syn!: [ :flux,
                                 :propensity,
                                 :rate_closure,
                                 :flux_closure,
                                 :propensity_closure,
                                 :Φ,
                                 :φ ]
      oo.may_have :action, syn!: :action_closure
      oo.may_have :timed

      # was the rate was given?
      @has_rate = oo.has? :rate

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
            check_in_upstream_description_for_R( oo )
        else
          @domain, @action_closure, @timed, @functional =
            check_in_upstream_description_for_r( oo )
        end

      # optional assignment action:
      @assignment_action = check_in_assignment_action( oo )
    end # def check_in_arguments
    
    # Makes sure that supplied collection consists only of appropriate places.
    # Second optional argument customizes the error message.
    # 
    def sanitize_place_collection place_collection, what_is_collection=nil
      c = what_is_collection ? what_is_collection.capitalize : "Collection"
      Array( place_collection ).map do |pl_id|
        begin
          place( pl_id )
        rescue NameError
          raise TErr, "#{c} member #{pl_id} does not specify a valid place!"
        end
      end.aT what_is_collection, "not contain duplicate places" do |collection|
        collection == collection.uniq
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
            .delete_if{ |place, coeff| coeff > 0 }.keys
        else
          :missing
          # Barring the caller's error, missing domain can mean:
          # 1. empty domain
          # 2. domain == codomain
          # This will be figured later by rate/action closure arity
        end
      end
    end

    def check_in_upstream_description_for_R( oo )
      _domain = domain               # this method may modify domain
      # check against colliding :action argument
      raise TErr, "Rate & action are mutually exclusive!" if oo.has? :action
      # lets figure the rate closure
      rate_λ = case rate_arg = oo[:rate]
               when Proc then # We received the closure directly,
                 # but we've to be concerned about missing domain.
                 if domain == :missing then # we've to figure user's intent
                   _domain = if rate_arg.arity == 0 then
                               [] # user meant empty domain
                             else
                               codomain # user meant domain same as codomain
                             end
                 else # domain not missing
                   raise TErr, "Rate closure arity (#{rate_arg.arity}) " +
                     "greater than domain size (#{domain.size})!" unless
                     rate_arg.arity.abs <= domain.size
                 end
                 rate_arg
               else # We received something else,
                 # we must make assumption user's intent.
                 if stoichiometric? then # user's intent was mass action
                   raise TErr, "When a number is supplied as rate, domain " +
                     "must not be given!" if oo.has? :domain
                   construct_standard_mass_action( rate_arg )
                 else # user's intent was constant closure
                   raise TErr, "When rate is a number and no stoichiometry " +
                     "is supplied, codomain size must be 1!" unless
                     codomain.size == 1
                   # Missing domain is OK here,
                   _domain = [] if domain == :missing
                   # but if it was supplied explicitly, it must be empty.
                   raise TErr, "Rate is a number, but non-empty domain was " +
                     "supplied!" unless domain.empty? if oo.has?( :domain )
                   lambda { rate_arg }
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

    def check_in_upstream_description_for_r( oo )
      _domain = domain               # this method may modify domain
      _functional = true
      # was action closure was given explicitly?
      if oo.has? :action then
        action_λ = oo[:action].aT_is_a Proc, "supplied action named argument"
        if oo.has? :timed then
          _timed = oo[:timed]
          # Time to worry about the domain_missing
          if domain == :missing then
            # figure user's intent from closure arity
            _domain = if action_λ.arity == ( _timed ? 1 : 0 ) then
                        [] # user meant empty domain
                      else
                        codomain # user meant domain same as codomain
                      end
          else # domain not missing
            raise TErr, "Rate closure arity (#{rate_arg.arity}) > domain " +
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
                        raise AErr, "Too much ambiguity: Neither domain nor " +
                          "timedness of the rateless transition was specified."
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
                       raise AErr, "Timedness was not specified, and the " +
                         "arity of the action supplied action closure " +
                         "(#{action_λ.arity}) does not give clear hint on it."
                     end
          end
        end
      else # rateless cases with no action closure specified
        # Assumption must be made on transition's action. In particular,
        # lambda { 1 } action closure will be assumed,
        action_λ = lambda { 1 }
        # and it will be required that the transition be stoichiometric and
        # timeless. Domain will thus be required empty.
        raise AErr, "Stoichiometry is compulsory, if rate/action was " +
          "not supplied." unless stoichiometric?
        # With this, we can drop worries about missing domain.
        raise AErr, "When no rate/action is supplied, the transition can't " +
          "be declared timed." if oo[:timed] if oo.has? :timed
        _timed = false
        _domain = []
        _functional = false # the transition is considered functionless
      end
      return _domain, action_λ, _timed, _functional
    end

    def construct_standard_mass_action( num )
      # assume standard mass-action law
      nonpositive_coeffs = stoichiometry.select { |coeff| coeff <= 0 }
      # the closure takes markings of the domain as its arguments
      lambda { |*markings|
        nonpositive_coeffs.size.times.reduce num do |acc, i|
          marking, coeff = markings[ i ], nonpositive_coeffs[ i ]
          # Stoichiometry coefficients equal to zero are taken to indicate
          # plain factors, assuming that if these places were not involved
          # in the transition at all, the user would not be mentioning them.
          case coeff
          when 0, -1 then marking * acc
          else marking ** -coeff end
        end
      }
    end

    # Private method, checking in downstream specification from the argument
    # field for stoichiometric transition.
    # 
    def check_in_downstream_description_for_S( oo )
      codomain, stoichio =
        case oo[:stoichiometry]
        when Hash then
          # contains pairs { codomain place => stoichiometry coefficient }
          raise AErr, "With hash-type stoichiometry, :codomain named " +
            "argument must not be supplied." if oo.has? :codomain
          oo[:stoichiometry].each_with_object [[], []] do |pair, memo|
            codomain_place, stoichio_coeff = pair
            memo[0] << codomain_place
            memo[1] << stoichio_coeff
          end
        else
          # array of stoichiometry coefficients
          raise AErr, "With array-type stoichiometry, :codomain named " +
            "argument must be supplied." unless oo.has? :codomain
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
      raise AErr, "For non-stoichiometric transitions, :codomain named " +
        "argument is compulsory." unless oo.has? :codomain
      return sanitize_place_collection( oo[:codomain], "supplied codomain" )
    end

    # Private method, part of #initialize argument checking-in.
    # 
    def check_in_assignment_action( oo )
      if oo.has? :assignment_action, syn!: [ :assignment, :assign, :A ] then
        if timed? then
          msg = "Timed transitions may not have assignment action!"
          raise TypeError, msg if oo[:assignment_action]
          false
        else       # timeless transitions are eligible for assignment action
          oo[:assignment_action]
        end
      else # if assignment action is not specified, false is 
        false
      end
    end
      
    # Place class pertinent herein. Provided for the purpose of parametrized
    # subclassing; expected to be overriden in the subclasses.
    # 
    def Place
      ::YPetri::Place
    end

    # Transition class pertinent herein. Provided for the purpose of
    # parametrized subclassing; expected to be overriden in the subclasses.
    # 
    def Transition
      ::YPetri::Transition
    end

    # Net class pertinent herein. Provided for the purpose of parametrized
    # subclassing; expected to be overriden in the subclasses.
    # 
    def Net
      ::YPetri::Net
    end

    # Presents Place instance specified by the argument.
    # 
    def place instance_identifier
      Place().instance( instance_identifier )
    end

    # Presents Transition instance specified by the argument.
    # 
    def transition instance_identifier
      Transition().instance( instance_identifier )
    end

    # Presents Net instance specified by the argument.
    # 
    def net instance_identifier
      Net().instance( instance_identifier )
    end
  end # class Transition
end # module YPetri
