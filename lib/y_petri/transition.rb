# -*- coding: utf-8 -*-

require_relative 'dependency_injection'
require_relative 'transition/arcs'
require_relative 'transition/cocking'
require_relative 'transition/construction'
require_relative 'transition/timed'
require_relative 'transition/ordinary_timeless'
require_relative 'transition/assignment'

# A Petri net transition. Usually depicted as square boxes, transitions
# represent operations over the net's marking vector -- how the marking changes
# when the transition activates (_fires_).
# 
# === Domain and codomin
#
# Each transition has a _domain_ -- upstream places. Upstream places are those,
# whose marking directly affects the transition's operation. Also, each
# transition has a _codomain_ -- downstream places. Downstream places are those,
# whose marking is directly affected by the transition's operation.
#
# === Action and action vector
#
# Every transition has an _action_ -- the operation it represents, the of what
# happens to the marking of its codomain when it fires. With respect to the
# transition's codomain, we can talk about the _action vector_ -- Δ state of the
# codomain. For _non-stoichiometric_ transitions, this action vector is given
# as the output of the _action closure_, or (for transitions with rate) of _rate
# vector_ * Δ_time. For _stoichiometric_ transitions, this output needs to be
# additionally multiplied by the transition's _stoichiometry vector_.
# 
# === Basic types of transitions
# 
# We have already mentioned different types of transitions _stoichiometric_ and
# _non-stoichometric_, with or without rate... In total, there are 6 basic types
# of transitions in *YPetri*:
#
# * *ts* – _timeless nonstoichiometric_
# * *tS* – _timeless stoichiometric_
# * *Tsr* – _timed rateless nonstoichiometric_
# * *TSr* – _timed rateless stoichiometric_
# * *sR* – _nonstoichiometric with rate_
# * *SR* – _stoichiometric with rate_
#
# These 6 kinds of YPetri transitions correspond to the vertices of a cube, with
# the following 3 dimensions:
# 
# - *Stoichiometricity*: _stoichiometric_ (S) / _nonstoichiometric_ (s)
# - *Timedness*: _timed_ (T) / _timeless_ (t)
# - *Having rate*: _having rate_ (R) / _not having rate_, _rateless_ (r)
# 
# ==== Stoichiometricity
# 
# I. For stoichiometric transitions:
#    1. Either *rate vector* is computed as *rate * stoichiometry vector*,
#    2. or *action vector* is computed a *action * stoichiometry vector*.
# II. For non-stoichiometric transitions:
#    1. Either *Rate vector* is obtained as the *rate closure result*,
#    2. or *action vector* is obtained as the *action closure result*.
# 
# Summary: stoichiometricity distinguishes the *need to multiply the rate/action
# closure result by stoichiometry*.
#
# ==== Having rate
# 
# I. For transitions with rate, the closure *returns the rate*. The rate has to
#    be multiplied by the time step (Δt) to get the action value.
# II. For transitions without rate (_rateless transitions_), the closure result
#     directly specifies the action.
#
# Summary: Having vs. not having rate distinguishes the *need to multiply the
# closure result by Δ time* -- differentiability of the action by time.
#
# ==== Timedness
# 
# I. Timed transitions are defined as those, whose action has time as a
#    parameter. Transitions with rate are thus always timed. For rateless
#    transitions, being timed means that the action closure expects time step
#    (Δt) as its first argument -- its arity is thus its codomain size + 1.
# II. Timeless transitions, in turn, are those, whose action is does not have
#     time a parameter. Timeless transitions are necessarily also rateless.
#     Arity of their action closure can be expected to match the domain size.
# 
# Summary: In rateless transitions, timedness distinguishes the *need to supply
# time step duration as the first argument to the action closure*. Whereas the
# transitions with rate are always timed, and vice-versa, timeless transitions
# always rateless, there are only 6 instead of 2 ** 3 == 8 basic types.
#
# === Other transition types
#
# ==== Assignment transitions (_A transitions_)
# If +:assignment_action+ is set to _true_, it indicates that the transition
# action entirely replaces the marking of its codomain with the result of its
# action closure -- like we are used to from spreadsheets. This behavior does
# not represent a truly novel type of a transition -- assignment transition is
# merely a *ts transition that cares to clear the codomain before adding the
# new value to it*. In other words, this behavior is (at least for numeric
# types) already achievable with ordinary ts transitions, and existence of
# specialized A transitions is just a convenience.
#
# ==== Functional / Functionless transitions
# YPetri is a domain model of _functional Petri nets_. Original Petri's
# definition does not speak about transition "functions". The transitions are
# defined as timeless and more or less assumed to be stoichiometric. Therefore,
# in +YPetri::Transition+ constructor, stoichiometric transitions with no
# function specified become functionless vanilla Petri net transitions.
#
# === "Discrete" vs. "continuous" in YPetri
#
# YPetri uses terminology of both "discrete" and "continuous" Petri nets. But
# in fact, in YPetri domain model, place marking is always considered discrete
# -- a discrete number of _tokens_, as defined by Carl Adam Petri. The meaning
# of _continuous_ in YPetri is different: A pragmatic measure of approximating
# this integer by a floating point number when the integer is so large, that the
# impact of this approximation is acceptable. The responsibility for the
# decision of how to represent the number of tokens is not a concern of the
# domain model, but only of the simulation method. Therefore, in YPetri, there
# are no _a priori_ "discrete" and "continuous" places or transitions.
#
# As for the transitions, terms _flux_ (flow), associated with continuous
# transitions, and _propensity_, associated with discrete stochastic
# transitions, are unified as _rate_. Again, the decision between "discrete"
# and "stochastic" is a concern of the simulation method, not the domain model.
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

  # In YPetri, _rate_ is a unifying term for both _flux_ and _propensity_,
  # both of which are treated as aliases of _rate_. The decision between
  # discrete and continuous computation is a concern of the simulation.
  # Rate closure arity should correspond to the transition's domain.
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

  # Zero action
  # 
  def zero_action
    codomain.map { 0 }
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
    "#<Transition: %s>" %
      "#{name.nil? ? '' : '%s ' % name }(#{basic_type}%s)%s" %
      [ "#{assignment_action? ? ' Assign.' : ''}",
        "#{name.nil? ? ' id:%s' % object_id : ''}" ]
  end
end # class YPetri::Transition
