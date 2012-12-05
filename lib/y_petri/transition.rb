#encoding: utf-8


module YPetri
  class Transition
    BASIC_TRANSITION_TYPES = {
      "ts" => "timeless nonstoichiometric transition",
      "tS" => "timeless stoichiometric transition",
      "Tsr" => "timed rateless nonstoichiometric transition",
      "TSr" => "timed rateless stoichiometric transition",
      "sR" => "nostoichiometric transition with rate",
      "SR" => "stoichiometric transition with rate"
    }

    include ConstMagicErsatz

    # Transition domain: Places whose marking directly affect its action.
    attr_reader :domain
    alias :domain_arcs :domain
    alias :domain_places :domain
    alias :upstream :domain
    alias :upstream_arcs :domain
    alias :upstream_places :domain
    def domain_pp; domain.map &:name end
    alias :upstream_pp :domain_pp
    def domain_pp_sym; domain_pp.map &:to_sym end
    alias :upstream_pp_sym :domain_pp_sym
    alias :domain_ppß :domain_pp_sym
    alias :ustream_ppß :domain_pp_sym

    # "Action arcs" is a collection of places, whose marking is directly
    # changed by firing the transition.
    attr_reader :codomain
    alias :codomain_arcs :codomain
    alias :codomain_places :codomain
    alias :downstream :codomain
    alias :downstream_arcs :codomain
    alias :downstream_places :codomain
    alias :action_arcs :codomain
    def codomain_pp; codomain.map &:name end
    alias :downstream_pp :codomain_pp
    def codomain_pp_sym; codomain_pp.map &:to_sym end
    alias :downstream_pp_sym :codomain_pp_sym
    alias :codomain_ppß :codomain_pp_sym
    alias :downstream_ppß :codomain_pp_sym

    # #arcs returns union of action arcs and test arcs.
    def arcs; domain | codomain end
    alias :connectivity :arcs
    def cc; connectivity.map &:name end
    def cc_sym; cc.map &:to_sym end
    alias :ccß :cc_sym

    # Is the transition stoichiometric?
    def stoichiometric?; @stoichiometric end
    alias :s? :stoichiometric?
    def nonstoichiometric?; not stoichiometric? end

    # Stoichiometry (implies that the transition is stoichiometric)
    attr_reader :stoichiometry
    def stoichio; Hash[ codomain.zip( @stoichiometry ) ] end
    def s; stoichio.with_keys { |k| k.name.to_sym } end

    # Does the transition have rate?
    def has_rate?; @has_rate end
    def rateless?; not has_rate? end

    # The term 'flux' (meaning flow) is associated with continuous transitions,
    # while term 'propensity' is used with discrete stochastic transitions.
    # By the design of YPetri, distinguishing between discrete and continuous
    # computation is the responsibility of the simulation method, considering
    # current marking of the transition's connectivity and quanta of its
    # codomain. To emphasize unity of 'flux' and 'propensity', term 'rate' is
    # used to represent both of them:
    attr_reader :rate_closure
    alias :rate :rate_closure
    alias :flux_closure :rate_closure
    alias :flux :rate_closure
    alias :propensity_closure :rate_closure
    alias :propensity :rate_closure

    # For rateless transition, action closure must be present:
    attr_reader :action_closure
    alias :action :action_closure

    # Does the transition's action depend on delta time?
    def timed?; @timed end
    def timeless?; not timed? end

    # Is the transition functional?
    # Explanation: If rate or action closure is supplied, a transition is alway
    # considered 'functional'. Otherwise, it is considered not 'functional'.
    # Note that even transitions that are not functional still have standard
    # action acc. to Petri's definition. Also note that a timed transition is
    # necessarily functional.
    def functional?; @functional end
    def functionless?; not functional? end

    # Reports transition membership in one of 6 basic types of YPetri transitions:
    # 1. ts ..... timeless nonstoichiometric
    # 2. tS ..... timeless stoichiometric
    # 3. Tsr .... timed rateless nonstoichiometric
    # 4. TSr .... timed rateless stoichiometric
    # 5. sR ..... nostoichiometric with rate
    # 6. SR ..... stoichiometric with rate
    def basic_type
      if has_rate? then stoichiometric? ? "SR" : "sR"
      elsif timed? then stoichiometric? ? "TSr" : "Tsr"
      else stoichiometric? ? "tS" : "ts" end
    end

    # Is it assignment transition?
    # A transition can be specified to have 'assignment action', in which
    # case it completely replaces codomain marking with the objects resulting
    # from the transition's action. Note that for numeric marking, specifying
    # assignment action is a matter of convenience, not necessity, as it can
    # be emulated by fully subtracting the present codomain values and adding
    # the numbers computed by the transition to them. Assignment action flag
    # is a matter of necessity only when codomain marking involves objects
    # not supporting subtraction/addition (which is out of the scope of Petri's
    # original specification anyway.)
    def assignment_action?; @assignment_action end
    alias :assignment? :assignment_action?

    # Is the transition cocked?
    # The transition has to be cocked before #fire method can be called
    # successfully. (Can be overriden using #fire! method.)
    def cocked?; @cocked end
    def uncocked?; not cocked? end

    def initialize *aa
      check_in_arguments *aa     # the big work of checking in the arguments
      # Inform the relevant places that they have been connected:
      upstream.each{ |place| place.register_downstream_transition self }
      downstream.each{ |place| place.register_upstream_transition self }
      # transitions initialize uncocked:
      @cocked = false
    end

    # Marking of the domain places
    def domain_marking; domain.map &:marking end

    # Marking of the codomain places
    def codomain_marking; codomain.map &:marking end

    # Result of the operating function, regardless of the enabling status.
    def action( Δt=nil )
      raise AE, "Δtime argument required for timed transitions!" if
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
    def zero_action; codomain.map {0} end

    # Changes to the marking of codomain exactly as they would happen if
    # #fire was called right now.
    def action_after_feasibility_check( Δt=nil )
      raise AE, "Δtime argument required for timed transitions!" if
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

    # Allows #fire method (#fire! is self-cocking)
    def cock; @cocked = true end
    alias :cock! :cock
    def uncock; @cocked = false end
    alias :uncock! :uncock

    # If #fire method of a transition applies its action (token adding/taking)
    # on its domain, depending on codomain marking. Time step is expected as
    # argument if the transition is timed.
    def fire( Δt=nil )
      raise AE, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      return false unless cocked?
      uncock
      fire! Δt
      return true
    end

    # #fire! (with bang) fires the transition without checking cocked status.
    def fire!( Δt=nil )
      raise AE, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      if assignment_action? then
        codomain
          .zip( Array action( Δt ) )
          .each{ |place, new_marking| place.marking = new_marking }
      else
        codomain
          .zip( action_after_feasibility_check( Δt ) )
          .each{ |place, change| place.add change }
      end
      return nil
    end


    # Sanity of execution is ensured by Petri's notion of transitions being
    # "enabled" if and only if the intended action can immediately take
    # place without getting places into forbidden state (negative marking).
    def enabled?( Δt=nil )
      raise AE, "Δtime argument required for timed transitions!" if
        timed? and Δt.nil?
      codomain
        .zip( action Δt )
        .all?{ |place, change| place.marking.to_f >= -change.to_f }
    end

    # Recursive firing of upstream net portion:
    def fire_upstream_recursively
      return false unless cocked?
      uncock
      upstream_places.each &:fire_upstream_recursively
      fire!
      return true
    end

    # Recursive firing of downstream net portion:
    def fire_downstream_recursively
      return false unless cocked?
      uncock
      fire!
      downstream_places.each &:fire_downstream_recursively
      return true
    end

    def force_disabled
      # LATER
    end
    alias :disable! :force_disabled

    def remove_force_disabled
      # LATER
    end
    alias :undisable! :remove_force_disabled

    def force_enabled!
      # LATER
    end

    def remove_force_enabled
      # LATER
    end

    def reset!
      uncock
      remove_force_disabled
      remove_force_enabled
      return self
    end

    # #inspect
    def inspect
      "YPetri::Transition[ #{name.nil? ? '' : name + ': ' }" +
        "#{BASIC_TRANSITION_TYPES[ basic_type ]}" +
        "#{assignment_action? ? ' with assignment action' : ''}" +
        "#{name.nil? ? ', object_id: %s' % object_id : ''} ]"
    end

    # #to_s
    def to_s
      "#{name.nil? ? 'Transition' : name }[ #{basic_type}%s ]" %
        if assignment_action? then " A" else "" end
    end
    
    private

    # **********************************************************************
    # ARGUMENT CHECK-IN UPON INITIALIZATION
    # **********************************************************************

    # The following big job is basically defining the duck type of the input
    # argument collection.
    def check_in_arguments *args; oo = args.extract_options!

      # Name is optional:
      @name = oo.may_have :name, syn!: :ɴ

      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
      # We'll first prepare the sanitization closure for place collections,
      # which makes sure that supplied array consists only of YPetri places.
      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
      # 
      sanit = lambda { |symbol|
        oo[symbol] = Array( oo[symbol] ).map { |e| ::YPetri::Place e }
        oo[symbol].aE "not contain duplicate places", "collection" do |array|
          array == array.uniq
        end
      }

      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
      # Downstream description arguments: codomain, stoichiometry...
      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

      # Let' see whether stoichiometric vector was given:
      @stoichiometric = oo.has? :stoichiometry, syn!: [ :stoichio, :s ]

      # Let's note whether codomain was given as separate argument:
      codomain_argument_given =
        oo.has? :codomain, syn!: [ :codomain_arcs,
                                   :codomain_places,
                                   :downstream,
                                   :downstream_arcs,
                                   :downstream_places,
                                   :action_arcs ]

      # Stoichiometric and non-stoichiometric case get separate treatment:
      if stoichiometric? then # stoichiometry was supplied as either:
        # I. Array, in which case codomain argument is required, or...
        # II. Hash { place => stoichiometric coefficient }, implying codomain.
        
        case oo[:stoichiometry]
        when Hash then # split that hash into codomain and stoichiometry
          @codomain, @stoichiometry =
            oo[:stoichiometry].each_with_object [[], []] do |pair, memo|
              memo[0] << ::YPetri::Place( pair[0] )
              memo[1] << pair[1]
            end
          raise AE, "With hash-type stoichiometry, :codomain argument " +
            "must not be supplied." if codomain_argument_given
        else # it is an array and accompanying :codomain parameter is expected
          @stoichiometry = Array oo[:stoichiometry]
          raise AE, "With array-type stoichiometry, :codomain argument " +
            "must be supplied." unless codomain_argument_given
          @codomain = sanit.( :codomain )
        end

        # Finally, enforce that stoichiometry vector is all numbers
        stoichiometry.aE_all_numeric "supplied stoichiometry"
      else # this is a non-stoichiometric transition
        # Codomain must be explicitly given - no way around it:
        raise AE, "For non-stoichiometric transitions, :codomain argument " +
          "must be supplied." unless codomain_argument_given
        @codomain = sanit.( :codomain )
      end

      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
      # Thus, codomain has been determined for all possible duck type cases.
      # Downstream part is now finished and we can move on the arguments
      # describing the upstream part: domain, action, timed/timeless...
      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

      # Let's note the domain argument:
      domain_argument_given = oo.has? :domain, syn!: [ :domain_arcs,
                                                       :domain_places,
                                                       :upstream,
                                                       :upstream_arcs,
                                                       :upstream_places ]

      # Let's note whether rate was given:
      @has_rate = oo.has? :rate, syn!: [ :flux,
                                         :propensity,
                                         :rate_closure,
                                         :flux_closure,
                                         :propensity_closure,
                                         :Φ,
                                         :φ ]

      # Let's note whether action was given
      action_given = oo.has? :action, syn!: :action_closure

      # Let's note whether timedness / timelessness was explicitly given:
      timed_given = oo.has? :timed
      timeless_given = oo.has? :timeless

      # Now, lets determine the transition domain:
      if domain_argument_given then # just sanitize it:
        @domain = sanit.( :domain )
        domain_missing = false # noting that domain is not missing
      else # domain was not given and we'll have to guess it

        # Breaking duck type into stoichiometric and non-stoichiometric case:
        if stoichiometric? then
          @domain = # arcs with non-positive stoichio. coeffs
            Hash[ [ @codomain, @stoichiometry ].transpose ]
              .delete_if{ |place, coeff| coeff > 0 }.keys
          domain_missing = false # noting that domain is not missing
        else # non-stoichiometric case
          # ----------------------------------------------------------------
          # Since domain was not given, then, barring the caller's error,
          # there are two possibilities of what the caller meant:
          # 1. Omitted domain means empty domain
          # 2. Omitted domain means domain == codomain
          # The only clue to distinguishing between these cases is arity
          # of the supplied rate or action closure. This decision will not
          # be made immediately here, but left to the code checking in
          # rate / action closures.
          # ----------------------------------------------------------------
          domain_missing = true      # noting that domain is missing
        end
      end

      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
      # Hereby, the domain question has been treated, except the case of
      # a non-stoichiometric transition with no explicitly supplied domain.
      #
      # Now is a good time to talk about transition classification:
      #
      # STOICHIOMETRIC / NON-STOICHIOMETRIC
      # I. For stoichiometric transitions:
      #    1. Rate vector is computed as rate * stoichiometry vector, or
      #    2. Δ vector is computed a action * stoichometry vector.
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
      # Now, let's try to say the same in Ruby code:
      # ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

      if has_rate? then # Case of transitions with rate
        @functional = true # transitions with rate are implicitly functional
        raise AE, "action closure must not be given when rate " +
          "closure was given" if action_given # action must not be given
        @timed = true # Transitions with rate are implicitly timed:
        # There must be no colliding :timed/:timeless named params
        oo[:timed].aE "be true if rate given",
                      ":timed named argument" if timed_given
        oo[:timeless].aE_not "be true if rate given",
                             ":timeless named argument" if timed_given
        @assignment_action = false # no assignment action
        
        case tentative_rate = oo[:rate] # let's look at what we've received
        when ~:to_f then # we received a number
          # Barring the caller's error, stoichiometry must have been supplied,
          # unless, by chance, codomain consists of only one place:
          if not stoichiometric? then
            if codomain.size == 1 then # codomain is just one place
              
              # The single number that we received under :rate is, in this
              # non-stoichiometric case, understood as constant rate:
              @rate_closure = λ { tentative_rate }

            else # multiple codomain places exist, and that's wrong
              raise AE, "Codomain may consist of only a single place " +
                "when supplied rate is a single standalone number and " +
                "no stoichiometry vector was supplied."
            end
            
            # Here, domain must be size 0, so it's allowed not to mention it:
            if domain_missing then @domain = []
            else # should it mentioned explicitly, it still must be []
              raise AE, "Single standalone number was supplied as rate, " +
                "but a non-empty domain was supplied." unless domain.size == 0
            end
            
          else # the transition is stoichiometric

            # In this case, mass action law will be used to derive the rate
            # closure from the number supplied as :rate. The transition is still
            # considered 'functional':
            nonpositive_coeffs = stoichiometry.select { |coeff| coeff <= 0 }
            @rate_closure = λ { |*markings| # markings of the domain places
              markings.zip( nonpositive_coeffs ).map { |m, coeff|
                next m if coeff == 0 # zero coeffs taken to indicate simple factors
                coeff == -1 ? m : m ** -coeff # otherwise normal mass action law:
              }.reduce( tentative_rate, :* ) # finally, take product * rate
            }
            # stoichiometric transition, so no need to check if domain_missing
          end
        when ~:call then # transitions with :rate specified as Proc object
          @rate_closure = tentative_rate # a Proc gets admitted right in
          
          # But we do have to be concerned about domain_missing being true. If
          # so, we have to figure out what did the caller mean.
          
          # Common error message text for the case of caller error.
          msg = "Unexpected arity (#{@rate_closure.arity}) of rate closure."

          if domain_missing then # we have to figure what did the caller mean
            if @rate_closure.arity == 0 then # the caller meant empty domain:
              @domain = []
            elsif @rate_closure.arity == codomain.size then
              # Caller meant that domain is same as codomain:
              @domain = codomain
            else # no good deduction of caller's intent possible:
              raise AE, msg.chop + ", domain should be given explicitly."
            end
          else
            # domain not missing, the arity must match the domain or be zero
            # (for fixed rate transitions)
            if @rate_closure.lambda? then
              if @rate_closure.arity != domain.size then
                raise AE, msg.chop + ", domain size is #{domain.size}"
              end
            else
              unless @rate_closure.arity.abs <= domain.size
                raise AE, msg.chop +
                  ", arity more than domain size (#{domain.size})"
              end
            end
          end
          
        else raise AE, "Object of unexpected class " +
            "(#{tentative_rate.class} given as :rate."
        end
      else # no :rate argument specified for this transition
        # Rateless transitions can be both timed or timeless.

        # Preventing possible collision:
        raise AE, ":timed and :timeless named arguments collision" if
          oo[:timed] != !oo[:timeless] if timed_given and timeless_given

        # Let' see whether action closure was given explicitly:
        action_given = oo.has? :action, syn!: :action_closure
        
        # Breaking down rateless transitions into with and wo action closure:
        if action_given then
          @action_closure = oo[:action].aE_is_a( Proc, "supplied :action" )
          @functional = true    # the transition still considered functional

          if timed_given or timeless_given then
            @timed = timed_given ? oo[:timed] : !oo[:timeless]
            
            # Time to worry about the domain_missing
            msg = "Unexpected arity (#{@action_closure.arity}) of " +
              "action closure."      # base error message

            if domain_missing then # gotta figure the caller's intent
              if @action_closure.arity == ( timed? ? 1 : 0 ) then
                @domain = [] # caller meant empty domain
              elsif @action_closure.arity == codomain.size + ( timed? ? 1 : 0 )
                @domain = codomain # caller meant that domain = codomain
              else # no way to figure what the caller meant
                raise AE, msg.chop + ", domain should be given explicitly."
              end
            else # domain not missing, but the size must match closure arity
              raise AE, msg unless
                @action_closure.arity == domain.size + ( timed? ? 1 : 0 )
            end
          else # neither :timed nor :timeless argument supplied

            # Even if the caller did not bother to inform us explicitly
            # about :timed / :timeless quality of this transition, deduction
            # is possible based domain size - if action closure arity matches
            # domain size exactly, leaving no space for time step argument,
            # then the transition can be assumed timeless. If action closure
            # arity equals domain size + 1, it can be assumed that it expects
            # time step as its first parameter, ie. the transition is timed.
            #
            # If no domain was supplied either, then there is no way to make
            # a reasonable assumption on caller's intent, barring when arity
            # of the supplied action closure is zero, where it is assumed
            # that the domain is empty.
            if domain_missing then
              case @action_closure.arity
              when 0 then # except this special case,
                @timed = false; @domain = [] # timeless & empty domain
              else # no deduction of intent possible
                raise AE, "Too much ambiguity: Action closure of arity " +
                  "#{@action_closure.arity} was suplied, but neither " +
                  "domain nor timedness of the transition was specified."
              end
            else # domain not missing, timed/timeless can be figured out:
              @timed = case @action_closure.arity
                       when domain.size then false
                       when domain.size + 1 then true
                       else raise AE, "unexpected arity " +
                           "(#{@action_closure.arity}) of action closure"
                       end
            end
          end

        else # rateless cases with no :action specified
          # Since every transition does have some action, assumption must be
          # made on it. In particular, lambda { 1 } will be taken for action,
          # and it will be required that the transition be stoichiometric and
          # timeless. Domain therefore will be required to be empty.
          @action_closure = lambda { 1 }

          raise AE, "stoichiometry vector must be given if no " +
            "rate / action closure was given." unless stoichiometric?
          # With this, we can also drop worries about domain_missing

          raise AE, ":timed can only be false if no rate and no " +
            "action closure was given" if timed_given and timed?
          raise AE, ":timeless can only be true if no rate and no " +
            "action closure was given" if timeless_given and timed?
          @timed = false
          
          @domain = []
          
          @functional = false # the transition considered not functional
        end
      end
      
      # The last thing: :assignment_action argument:
      assignment_action_given = oo.has? :assignment_action,
                                syn!: [ :assignment,
                                        :assign ]
      if assignment_action_given
        if timed? then # timed transitions may not have asssignment action
          @assignment_action = false
          raise AE, "timed transitions cannot have assignment action" if
            oo[:assignment_action] == true
        else # timeless may
          @assignment_action = oo[:assignment_action]
        end
      else # if not given then implied false
        @assignment_action = false
      end
    end # def check_in_arguments
  end # class Transition
end # module YPetri
