# -*- coding: utf-8 -*-

require_relative 'dependency_injection'
require_relative 'transition/arcs'
require_relative 'transition/cocking'
require_relative 'transition/constructor_syntax'

# A Petri net transition. There are 6 basic types of YPetri transitions:
#
# * <b>ts</b> – timeless nonstoichiometric
# * <b>tS</b> – timeless stoichiometric
# * <b>Tsr</b> – timed rateless nonstoichiometric
# * <b>TSr</b> – timed rateless stoichiometric
# * <b>sR</b> – nonstoichiometric with rate
# * <b>SR</b> – stoichiometric with rate
#
# These 6 kinds of YPetri transitions correspond to the vertices of a cube,
# whose 3 dimensions are:
# 
# - stoichiometric (S) / nonstoichiometric (s)
# - timed (T) / timeless (t)
# - having rate (R) / not having rate (r)
# 
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
# I. For transitions with rate, the closure result has to be
#    multiplied by the time step duration (delta_t) to get action.
# II. For rateless transitions, the closure result is used as is.
#
# Conclusion: has_rate? distinguishes *need to multiply the closure
# result by delta time* -- differentiability of action by time.
# 
# I. For timed transitions, action is time-dependent. Transitions with
#    rate are thus always timed. In rateless transitions, timedness means
#    that the action closure expects time step length (delta_t) as its first
#    argument - its arity is thus codomain size + 1. 
# II. For timeless transitions, action is time-independent. Timeless
#     transitions are necessarily also rateless. Arity of the action closure
#     is expected to match the domain size.
# 
# Conclusion: Transitions with rate are always timed. In rateless
# transitions, timedness distinguishes the need to supply time step
# duration as the first argument to the action closure.
# 
# Since transitions with rate are always timed, and vice-versa, timeless
# transitions cannot have rate, there are not 8, but only 6 permissible
# combinations -- 6 basic transition types listed above.
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
class YPetri::Transition
  include NameMagic
  include YPetri::DependencyInjection

  BASIC_TRANSITION_TYPES = {
    ts: "timeless nonstoichiometric transition",
    tS: "timeless stoichiometric transition",
    Tsr: "timed rateless nonstoichiometric transition",
    TSr: "timed rateless stoichiometric transition",
    sR: "nonstoichiometric transition with rate",
    SR: "stoichiometric transition with rate"
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

  # Codomain, 'downstream arcs', or 'action arcs', is a collection of places,
  # whose marking is directly changed by this transition's firing.
  # 
  attr_reader :codomain
  alias :codomain_arcs :codomain
  alias :codomain_places :codomain
  alias :downstream :codomain
  alias :downstream_arcs :codomain
  alias :downstream_places :codomain
  alias :action_arcs :codomain

  # Is the transition stoichiometric?
  # 
  def stoichiometric?; @stoichiometric end
  alias :s? :stoichiometric?

  # Is the transition nonstoichiometric? (Opposite of #stoichiometric?)
  # 
  def nonstoichiometric?
    not stoichiometric?
  end

  # Stoichiometry (implies that the transition is stoichiometric).
  # 
  attr_reader :stoichiometry

  # Stoichiometry as a hash of pairs:
  # { codomain_place_instance => stoichiometric_coefficient }
  # 
  def stoichio
    Hash[ codomain.zip( @stoichiometry ) ]
  end

  # Stoichiometry as a hash of pairs:
  # { codomain_place_name_symbol => stoichiometric_coefficient }
  # 
  def s
    stoichio.with_keys { |k| k.name || k.object_id }
  end

  # Does the transition have rate?
  # 
  def has_rate?
    @has_rate
  end

  # Is the transition rateless?
  # 
  def rateless?
    not has_rate?
  end

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
  def timed?
    @timed
  end

  # Is the transition timeless? (Opposite of #timed?)
  # 
  def timeless?
    not timed?
  end

  # Is the transition functional?
  # Explanation: If rate or action closure is supplied, a transition is always
  # considered 'functional'. Otherwise, it is considered not 'functional'.
  # Note that even transitions that are not functional still have standard
  # action acc. to Petri's definition. Also note that a timed transition is
  # necessarily functional.
  # 
  def functional?
    @functional
  end

  # Opposite of #functional?
  # 
  def functionless?
    not functional?
  end

  # Reports the transition's membership in one of 6 basic types :
  # 1. ts ..... timeless nonstoichiometric
  # 2. tS ..... timeless stoichiometric
  # 3. Tsr .... timed rateless nonstoichiometric
  # 4. TSr .... timed rateless stoichiometric
  # 5. sR ..... nonstoichiometric with rate
  # 6. SR ..... stoichiometric with rate
  # 
  def basic_type
    if has_rate? then stoichiometric? ? :SR : :sR
    elsif timed? then stoichiometric? ? :TSr : :Tsr
    else stoichiometric? ? :tS : :ts end
  end

  # Reports transition's type (basic type + whether it's an assignment
  # transition).
  # 
  def type
    assignment_action? ? "A(ts)" : basic_type
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

  # Result of the transition's "function", regardless of the #enabled? status.
  # 
  def action Δt=nil
    raise ArgumentError, "Δtime argument required for timed transitions!" if
      timed? and Δt.nil?
    # the code here looks awkward, because I was trying to speed it up
    if has_rate? then
      if stoichiometric? then
        rate = rate_closure.( *domain_marking )
        stoichiometry.map { |coeff| rate * coeff * Δt }
      else # assuming correct return value arity from the rate closure:
        rate_closure.( *domain_marking ).map { |e| component * Δt }
      end
    else # rateless
      if timed? then
        if stoichiometric? then
          rslt = action_closure.( Δt, *domain_marking )
          stoichiometry.map { |coeff| rslt * coeff }
        else
          action_closure.( Δt, *domain_marking ) # caveat result arity!
        end
      else # timeless
        if stoichiometric? then
          rslt = action_closure.( *domain_marking )
          stoichiometry.map { |coeff| rslt * coeff }
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
      .all? { |place, change| place.marking.to_f >= -change.to_f }
    if enabled then act else
      raise "firing of #{self}#{ Δt ? ' with Δtime %s' % Δt : '' } " +
        "would result in negative marking"
      zero_action
    end
    # LATER: This use of #zip here should be avoided for speed
  end

  # Applies transition's action (adding/taking tokens) on its downstream
  # places (aka. domain places). If the transition is timed, delta time has
  # to be supplied as argument. In order for this method to work, the
  # transition has to be cocked (#cock method), and firing uncocks the
  # transition, so it has to be cocked again before it can be fired for
  # the second time. If the transition is not cocked, this method has no
  # effect.
  # 
  def fire( Δt=nil )
    raise ArgumentError, "Δtime argument required for timed transitions!" if
      timed? and Δt.nil?
    return false unless cocked?
    uncock
    fire! Δt
    return true
  end

  # Fires the transition just like #fire method, but disregards the cocked /
  # uncocked state of the transition.
  # 
  def fire!( Δt=nil )
    raise ArgumentError, "Δt required for timed transitions!" if
      Δt.nil? if timed?
    try "to fire" do
      if assignment_action? then
        note has: "assignment action"
        act = note "action", is: Array( action( Δt ) )
        codomain.each_with_index do |place, i|
          "place #{place}".try "to assign marking #{i}" do
            place.marking = act[i]
          end
        end
      else
        act = note "action", is: action_after_feasibility_check( Δt )
        codomain.each_with_index do |place, i|
          "place #{place}".try "to assign marking #{i}" do
            place.add act[i]
          end
        end
      end
    end
    return nil
  end

  # Sanity of execution is ensured by Petri's notion of transitions being
  # "enabled" if and only if the intended action can immediately take
  # place without getting places into forbidden state (negative marking).
  # 
  def enabled?( Δt=nil )
    fail ArgumentError, "Δtime argument compulsory for timed transitions!" if
      timed? && Δt.nil?
    codomain.zip( action Δt ).all? do |place, change|
      begin
        place.guard.( place.marking + change )
      rescue YPetri::GuardError
        false
      end
    end
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
end # class YPetri::Transition
