# -*- coding: utf-8 -*-
# This class represents Petri net places.
# 
class YPetri::Place
  include NameMagic

  # Marking guard.
  # 
  class Guard
    MESSAGE = -> ( marking, assertion ) {
      "Marking '#{marking}' (class #{marking.class}) #{assertion}!"
    }

    attr_reader :assertion, :block

    # Requires guard assertion formulated as a string in natural language
    # (will be used to inform the user in case of GuardError), and a guard
    # block. The block is considered failed if it either returns <em>false</em>
    # value (<nil> is considered OK!), or if it raises GuardError on its own.
    # For this purpose, fail method is conveniently redefined to raise
    # appropriately worded GuardError inside the block.
    # 
    def initialize assertion_in_natural_language, &block
      @assertion = assertion_in_natural_language
      @block = block
    end

    # Given a marking, validates whether the marking passes the guard block.
    # If not, GuardError is raised either by the guard block itself, or by
    # this method, if the guard block returns false.
    # 
    def validate( m )
      fλ = lambda { raise YPetri::GuardError, MESSAGE.( m, assertion ) }
      fλ.call if Object.new.tap { |o|
        o.define_singleton_method :fail, &fλ
      }.instance_exec( m, &block ) == false # nil is OK!
      return true
    end
  end

  attr_reader :quantum
  attr_reader :guards
  attr_accessor :default_marking
  attr_writer :marking

  # Simple getter of @marking attribute.
  # 
  def m; @marking end
  alias value m

  # Without arguments, acts as a mere getter of @marking instance variable.
  # If, however, a textual assertion about the marking and a guard block is
  # supplied, this method creates a marking guard just like #guard method:
  #
  # - marking "should be a number" do |m| fail unless m.is_a? Numeric end
  #
  # See #guard method for more information.
  # 
  def marking *args, &block
    return @marking if args.empty?
    fail ArgumentError, "Too many arguments!" if args.size > 1
    guard args[0], &block
  end

  # Expects a unary block encoding a guard about the place's marking. If the
  # block returns a <em>false</em> value (<em>nil</em> is OK!), or raises
  # YPetrk::GuardError, guard assertion is considered as having failed for the
  # supplied marking. Also expects a string argument expressing the assertion
  # in natural speech. GuardError raising from inside the block is facilitated
  # by #fail method being redefined inside the block to raise appropriately
  # worded GuardError:
  #
  # - guard "should be a number" do |m| fail unless m.is_a? Numeric end
  #
  # Then guard!( :not_a_number ) raises YPetri::GuardError with message "Marking
  # 'not_a_number' (class Symbol) should be a number!"
  #
  # If no block is given to this method, it returns the federated guard closure
  # for this place.
  # 
  def guard *args, &block
    if block then
      @guards << Guard.new( *args, &block )
    else
      federated_guard_closure
    end
  end

  # Returns a joint guard closure composed of individual guards, defined at
  # this moment. The closure that is returned by this method is not affected
  # by subsequent changes in the place's guard lineup.
  # 
  def federated_guard_closure
    current_guard_lineup = guards.dup
    lambda do |m| current_guard_lineup.each { |g| g.validate m }; true end
  end

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
  # As for marking guards (:guard argument), if nothing is given, default
  # marking guards are used, inferred from the type of supplied :marking or
  # :default_marking. Alternatively, a single guard can be given explicitly
  # upon place initialization by supplying a guard block, and (optionally)
  # supplying the natural language assertion (for error message) in :guard
  # argument. Use of default marking guards can be turned of by setting
  # :guard argument explicitly to false.
  # 
  def initialize( quantum: 1, default_marking: nil, marking: nil,
                  guard: L!, &block )
    @upstream_arcs, @downstream_arcs = [], [] # init to empty
    @quantum = quantum
    @default_marking = default_marking
    @marking = marking || default_marking
    @guards = [] # init to no guards
    if guard.ℓ? then # use either block (if given), or default guards
      if block then self.guard &block else add_default_guards! @marking end
    elsif guard # guard nl assertion given
      fail ArgumentError, "No guard block given!" unless block
      self.guard( guard, &block )
    else
      fail ArgumentError, "Block not accepted if guard set to falsey!" if block
    end
  end

  # Returns an array of all the transitions connected to the place.
  # 
  def arcs
    upstream_arcs | downstream_arcs
  end

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

  # Applies guard on the marking.
  # 
  def guard!
    msg = "Marking %s of place #{ɴ_} fails its guard!"
    lambda do |m|
      gg.inject true do |m, g| m && g.( m ) end or
        fail YPetri::GuardError, msg % m
    end

    guard.( @marking )
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

  # Produces the inspect string of the place.
  # 
  def inspect
    n, m, d, q = instance_description_strings
    "#<Place: #{ ( USE_QUANTUM ? [n, m, d, q] : [n, m, d] ).join ', ' } >"
  end

  # Returns a string briefly describing the place.
  # 
  def to_s
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
    nς = "name: #{n.nil? ? '∅' : n}"
    mς = "marking: #{m.nil? ? 'nil' : m}"
    dς = "default_marking: #{d.nil? ? '∅' : d}"
    qς = "quantum: #{q.nil? ? '∅' : q}"
    return nς, mς, dς, qς
  end

  # If no marking guard closures were supplied by the user, this method can make
  # them up, using user-supplied marking or default marking as a type reference.
  # By default, numeric types are interchangeable, except complex numbers, and
  # are not allowed to be negative.
  # 
  def add_default_guards!( reference_marking )
    ref_class = reference_marking.class
    if ref_class < Numeric and not ref_class < Complex then
      marking "should be a number" do |m| m.is_a? Numeric end
      marking "should not be complex" do |m| fail if m.is_a? Complex end
    else
      marking "should be a #{ref_class}" do |m| m.is_a? ref_class end
    end
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
end # class YPetri::Place
