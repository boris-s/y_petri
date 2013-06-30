# -*- coding: utf-8 -*-

require_relative 'dependency_injection'
require_relative 'transition/arcs'
require_relative 'transition/cocking'
require_relative 'transition/construction'
require_relative 'transition/timed'
require_relative 'transition/ordinary_timeless'
require_relative 'transition/assignment'

# Transitions -- little boxes in Petri net drawings -- represent atomic
# operations on the Petri net's marking.
# 
# === Domain and codomin
#
# Each transition has a _domain_ (upstream places) and _codomain_ (downstream
# places). Upstream places are those, whose marking directly affects
# the transition. Downstream places are those, whose marking is directly affected
# by the transition.
#
# === Action and action vector
#
# Every transition has an _action_ -- the operation it represents. The action
# of _non-stoichiometric_ transitions is directly specified by the _action_
# _closure_ (whose output arity should match the codomain size.) For
# _stoichiometric_ transitions, the result of the action closure has to be
# multiplied by the transition's _stoichiometry_ _vector_ to obtain the action.
# Action of the _transitions_ _with_ _rate_ is specified indirectly by the
# _rate_ _closure_.
# 
# === Rate
#
# In YPetri domain model, marking is always a discrete number of _tokens_ -- as
# Carl Adam Petri handed it down to us. YPetri recognizes the usefulness of
# representing a large number of tokens by a floating point number, but sees it
# as a pragmatic measure only. Other Petri net implementations often make class
# distincion between discrete and continuous places, and also distinguish between
# _flux_ ("flow" of the continous transitions) and _propensity_ (firing
# probability of discrete transitions). In YPetri, flux and propensity are
# unified under the term _rate_, and the choice between discrete and stochastic
# computation is seen as a concern of the simulation, not of the model.
# 
# === Basic transition types
# 
# There are 6 basic types of transitions in YPetri:
#
# * *ts* – timeless nonstoichiometric
# * *tS* – timeless stoichiometric
# * *Tsr* – timed rateless nonstoichiometric
# * *TSr* – timed rateless stoichiometric
# * *sR* – nonstoichiometric with rate
# * *SR* – stoichiometric with rate
#
# They arise by combining the 3 basic qualities:
# 
# 1. *Stoichiometricity*: _stoichiometric_ (*S*) / _nonstoichiometric_ (*s*)
# 2. *Timedness*: _timed_ (*T*) / _timeless_ (*t*)
# 3. *Having* *rate*: having _rate_ (*R*) / not having rate (_rateless_) (*r*)
# 
# ==== 1. Stoichiometricity
# 
# * For *stoichiometric* transitions:
#   - _either_ <b>rate vector</b> is obtained as
#     <b>rate * stoichiometry vector</b>,
#   - _or_ <b>action vector</b> is obtained as
#     <b>action * stoichiometry vector</b>
# * For *non-stoichiometric* transitions:
#   - _either_ <b>rate vector</b> is obtained as the <b>rate closure result</b>,
#   - _or_ <b>action vector</b> is obtained as the <b>action closure result</b>.
# 
# Summary: stoichiometricity distinguishes the <b>need to multiply the
# rate/action closure result by stoichiometry</b>.
#
# ==== 2. Having rate
# 
# * Transitions *with* *rate* have a _rate_ _closure_, whose result is to be
#   multiplied by +Δt+.
# * For transitions *without* *rate* (*rateless* transitions), the action
#   closure specifies the action *directly*.
#
# Summary: Having vs. not having rate distinguishes the <b>need to multiply the
# closure result by Δ time</b> -- differentiability of the action by time.
#
# ==== 3. Timedness
# 
# * Timed transitions are defined as those, whose action has time as a parameter.
#   - Transitions with rate are therefore always timed.
#   - For rateless transitions, being timed means, that their action closure
#     <b>expects Δt as its first argument</b> -- arity thus equals codomain
#     size + 1.
# * Timeless transitions are those, whose action does not have time as
#   a parameter. Timeless transitions are necessarily also rateless.
# 
# Summary: In rateless transitions, timedness distinguishes the <b>need to
# supply time step duration as the first argument to the action closure</b>.
# As the transitions with rate are necessarily timed, and timeless transitions
# necessarily rateless, there are only 6 instead of 2 ** 3 == 8 transition types.
#
# === Other transition attributes
#
# ==== Assignment transitions (_A_ _transitions_)
# If +:assignment_action+ option is set to _true_, it makes the transition
# entirely replace the codomain marking with its action closure result -- just
# like spreadsheet functions do. This, however, is just a convenience, and does
# not constitue a novel transition type, as it can be easily emulated by an
# ordinary ts transition caring to subtract the current domain marking before
# adding the desired values.
#
# ==== _Functional_ / _functionless_ transitions
# Other Petri net implementation often make a distinction between "ordinary"
# and "functional" transitions, where "ordinary" ("functionless") are the
# transitions as Carl Adam Petri handed them down to us. YPetri transtions
# are generally "functional", but the possibility of functionless transitions
# is also provided -- stoichiometric transitions with no action or rate
# specified become functionless transitions.
# definition does not speak about transition "functions". The transitions are
# defined as timeless and more or less assumed to be stoichiometric. Therefore,
# in +YPetri::Transition+ constructor, stoichiometric transitions with no
# function specified become functionless vanilla Petri net transitions.
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
