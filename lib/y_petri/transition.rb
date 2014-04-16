# encoding: utf-8

require_relative 'transition/arcs'
require_relative 'transition/cocking'
require_relative 'transition/construction_convenience'
require_relative 'transition/types'
require_relative 'transition/usable_without_world'

# Transitions -- little boxes in Petri net drawings -- represent atomic
# operations on the Petri net's marking.
# 
# === Domain and codomin
#
# Each transition has a _domain_ (upstream places) and _codomain_ (downstream
# places). Upstream places are those, whose marking affects the transition.
# Downstream places are those affected by the transition.
#
# === Action and action vector
#
# Every transition _action_ -- the operation it represents. The action of
# _non-stoichiometric_ transitions is directly specified by its _action_
# _closure_ (whose output arity should match the codomain size.) For
# _stoichiometric_ transitions, the action closure result must be multiplied
# by the transition's _stoichiometry_ _vector_. _Timed_ _transitions_ have
# _rate_ _closure_. Their action can be obtained by multiplying their rate
# by Δtime.
# 
# === Rate
#
# In YPetri, marking is always considered a discrete number of _tokens_ (as
# C. A. Petri has handed it down to us). Usefulness of floating point numbers
# in representing larger amounts of tokens is acknowledged, but seen as a
# pragmatic measure, an implementation detail. There is no class distinction
# between discrete vs. continuous places / transitions. Often we see continuous
# transitions with their _flux_ (flow rate) ditinguished from discrete
# stochastic transitions with their _propensity_ (likelihood of firing in a
# time unit). In YPetri, flux and propensity are unified under a single term
# _rate_, and the choice between discrete and stochastic computation is a
# concern of the simulation, not of the object model.
# 
# === Basic transition types
# 
# There are 4 basic transition types in YPetri:
#
# * *TS* – timed stoichiometric
# * *tS* – timeless stoichiometric
# * *Ts* – timed nonstoichiometric
# * *ts* – timeless nonstoichiometric
#
# They arise by combining 2 qualities:
# 
# 1. *Timedness*: _timed_ (*T*) / _timeless_ (*t*)
# 2. *Stoichiometricity*: _stoichiometric_ (*S*) / _nonstoichiometric_ (*s*)
# 
# ==== Timedness

# 
# * Timed transitions have _rate_ _closure_, whose result is to be multiplied
#   by +Δtime+.
# * Timeless transitions have _action_ _closure_, whose result does not need
#   to be multiplied by time.
#   
# Summary: Having vs. not having rate distinguishes the <em>need to multiply the
# closure result by Δ time</em>.
# 
# ==== Stoichiometricity
#
# * *TS* transitions -- <b>rate vector = rate * stoichiometry vector</b>
# * *tS* transitions -- <b>action vector = action * stoichiometry vector</b>
# * *Ts* transitions -- <b>rate vector = rate closure result</b>
# * *ts* transitions -- <b>action vector = action closure result</b>
# 
# Summary: stoichiometricity distinguishes the <em>need to multiply the rate/action
# closure result by stoichiometry</em>.
# 
# === Assignment action
# 
# _Assignment_ _transitions_ (_*A*_ _transitions_) are special transitions, that
# _replace_ the codomain marking rather than modifying it -- they _assign_ new
# marking to their codomain, like we are used to from spreadsheets. Technically,
# this behavior is easily achievable with normal *ts* transitions, so the
# existence of separate *A* transitions is just a convenience, not a new type of
# a transition in the mathematical sense.
#
# ==== _Functional_ / _functionless_ transitions
# 
# Other Petri net implementation often distinguies between "ordinary" (vanilla
# as per C. A. Petri) and _functional_ transitions, whose operation is governed
# by a function. In YPetri, transitions are generally _functional_, but there
# remains a possibility of creating vanilla (_functionless_) transitions by not
# specifying any rate / action, while specifying the stoichiometry. Action
# closure as per C. A. Petri is automatically constructed for these.
# 
class YPetri::Transition
  ★ NameMagic                        # ★ means include
  ★ YPetri::World::Dependency
  ★ UsableWithoutWorld
  ★ Arcs
  ★ Cocking
  ★ ConstructionConvenience
  ★ Types

  class << self
    ★ YPetri::World::Dependency

    private :new
  end

  TYPES = {
    T: "timed",
    t: "timeless",
    S: "stoichiometric",
    s: "non-stoichiometric",
    A: "assignment",
    a: "non-assignment",
    TS: "timed stoichiometric",
    tS: "timeless stoichiometric",
    Ts: "timed nonstoichiometric",
    ts: "timeless nonstoichiometric"
  }

  delegate :world, to: "self.class"

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
    extend( if timed? then Type_T
            elsif assignment_action? then Type_A
            else Type_t end )
    inform_upstream_places         # that they have been connected
    inform_downstream_places       # that they have been connected
    uncock                         # initialize in uncocked state
  end

  # Domain, or 'upstream arcs', is a collection of places, whose marking
  # directly affects the transition's action.
  # 
  attr_reader :domain
  alias domain_arcs domain
  alias domain_places domain
  alias upstream domain
  alias upstream_arcs domain
  alias upstream_places domain

  # Codomain, 'downstream arcs', or 'action arcs', is a collection of places,
  # whose marking is directly changed by this transition's firing.
  # 
  attr_reader :codomain
  alias codomain_arcs codomain
  alias codomain_places codomain
  alias downstream codomain
  alias downstream_arcs codomain
  alias downstream_places codomain
  alias action_arcs codomain

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

  # In YPetri, _rate_ is a unifying term for both _flux_ and _propensity_,
  # both of which are treated as aliases of _rate_. The decision between
  # discrete and continuous computation is a concern of the simulation.
  # Rate closure arity should correspond to the transition's domain.
  # 
  attr_reader :rate_closure
  alias rate rate_closure
  alias flux_closure rate_closure
  alias flux rate_closure
  alias propensity_closure rate_closure
  alias propensity rate_closure

  # For rateless transition, action closure must be present. Action closure
  # input arguments must correspond to the domain places, and for timed
  # transitions, the first argument of the action closure must be Δtime.
  # 
  attr_reader :action_closure
  alias action action_closure

  # Zero action.
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

  # Let's just leave this to NameMagic

  # # Conversion to a string.
  # # 
  # def to_s
  #   "#<Transition: %s>" %
  #     "#{'%s ' % name if name}(#{type})#{' id:%s' % object_id unless name}"
  # end

  def place id
    super rescue Place().instance( id )
  end

  def transition id
    super rescue Transition().instance( id )
  end
end # class YPetri::Transition
