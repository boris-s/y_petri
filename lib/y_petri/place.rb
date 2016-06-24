# encoding: utf-8

require_relative 'place/guard'
require_relative 'place/guarded'
require_relative 'place/arcs'
require_relative 'place/features'

# Represents a Petri net place.
# 
class YPetri::Place
  ★ NameMagic                        # ★ means include
  ★ YPetri::World::Dependency
  ★ Arcs
  ★ Guarded
  ★ Features

  class << self
    ★ YPetri::World::Dependency
    private :new
  end

  delegate :world, to: "self.class"

  attr_reader :quantum
  attr_reader :guards
  attr_reader :has_default_marking
  alias has_default_marking? has_default_marking
 
  def default_marking
    fail TypeError, "No default marking was specified for #{self}!" unless
      has_default_marking?
    @default_marking
  end

  def default_marking= marking
    @has_default_marking = true
    @default_marking = marking
  end

  # Arguments supplied upon place initialization may include:
  # 
  # * +:marking+
  # * +:default_marking+
  # * +:quantum+
  # * +:guard+
  # 
  # +Marking+ is a standard attribute of a Petri net place, +default_marking+
  # is marking upon calling the reset method. Default marking may also be used
  # as the initial value in the simulations involving the place in question.
  # +Quantum+ attribute is not in use presently. In the future, it might be used
  # in deciding when to switch between continuous and discrete stochastic
  # representation of the marking. +Guard+ is a restriction to the place's
  # marking. (For example, the place could only admit non-negative numbers,
  # or numbers smaller than 1, or odd numbers etc.) Any number of guards can
  # be specified for a constructed place via +Place#guard+ method. For the cases
  # when a place has only one guard, it is, as a syntactic sugar, possible to
  # introduce exactly one guard already upon place initialization by supplying
  # to this constructor, in addition to other parameters, a string expressing
  # the guard as +:guard+ and a block expressing the same guard in code. If no
  # guard block is supplied to this constructor, default guards are constructed
  # based on the data type of the +:marking+ or +:default_marking+ argument. If
  # it is wished that the place has no guards whatsoever, +:guard+ should be set
  # to _false_.
  # 
  def initialize guard: L!, **named_args, &block
    @upstream_arcs, @downstream_arcs, @guards = [], [], [] # init to empty
    @quantum = named_args.has?( :quantum ) ? named_args[:quantum] : 1
    named_args.may_have :default_marking, syn!: :m!
    if named_args.has? :default_marking then
      @has_default_marking = true
      @default_marking = named_args[:default_marking]
    else
      @has_default_marking = false
    end
    if named_args.has? :marking then @marking = named_args[:marking] else
      @marking = default_marking if has_default_marking?
    end
    # Check in :guard value and the corresponding &block.
    if guard.ℓ? then # guard NL assertion not given, use block or default guards
      block ? guard( &block ) : add_default_guards!( @marking )
    elsif guard then # guard NL assertion given
      fail ArgumentError, "No guard block given!" unless block
      guard( guard, &block )
    else
      fail ArgumentError, "Block given, but :guard argument is falsey!" if block
    end
  end

  # Used without arguments, it is a getter of the place's +@marking+ attribute,
  # just like the +Place#m+ method. However, if a string and a block is supplied
  # to it, it acts as an alias of the +Place#guard+ method. This is because this:
  #
  #   marking "should be a number" do |m| fail unless m.is_a? Numeric end
  # 
  # reads better than this:
  # 
  #   guard "should be a number" do |m| fail unless m.is_a? Numeric end
  #
  # {See #guard method}[rdoc-ref:YPetri::guard] for more information.
  # 
  def marking *args, &block
    return @marking if args.empty?
    fail ArgumentError, "Too many arguments!" if args.size > 1
    guard args[0], &block
  end

  # Near-alias for #marking.
  # 
  def value
    marking
  end

  # Getter of the place's marking attribute under a simulation (current
  # simulation by default).
  # 
  def m simulation=world.simulation
    simulation.net.State.Feature.Marking( self ) % simulation
  end

  # Marking setter.
  # 
  def marking=( new_marking )
    @marking = guard.( new_marking )
  end

  # Alias for #marking=
  # 
  def value=( marking )
    self.marking = marking
  end

  # Alias for #marking=
  # 
  def m=( marking )
    self.marking = marking
  end

  # Adds tokens to the place's +@marking+ instance variable.
  # 
  def add( amount )
    @marking = guard.( @marking + amount )
  end

  # Subtracts tokens from the place's +@marking+ instance variable.
  # 
  def subtract( amount )
    @marking = guard.( @marking - amount )
  end

  # Resets the place's marking back to its default value (+@default_marking
  # instance variable).
  # 
  def reset_marking
    fail TypeError, "No default marking was specified for #{self}!" unless
      has_default_marking?
    @marking = guard.( @default_marking )
  end

  # Convenience visualizer of the upstream net.
  # 
  def uv
    upstream_net.visualize
  end

  # Let's try leave these to NameMagic

  # # Builds an inspect string of the place.
  # # 
  # def inspect
  #   n, m, d, q = instance_description_strings
  #   "#<Place: #{ ( [n, m, d, q].compact ).join ', ' }>"
  # end

  # # Returns a string representing the place.
  # # 
  # def to_s
  #   n, m = name, marking
  #   "#{n.nil? ? 'Place' : n}[#{m.nil? ? 'nil' : m}]"
  # end

  private

  def instance_description_strings
    m, n, q = marking, name, quantum
    mς = "marking: #{m.nil? ? 'nil' : m}"
    nς = "name: #{n.nil? ? '∅' : n}"
    qς = q == 1 ? nil : "quantum: #{q.nil? ? '∅' : q}"
    dς = "default_marking: #{has_default_marking ? default_marking : '∅'}"
    return nς, mς, dς, qς
  end
end # class YPetri::Place
