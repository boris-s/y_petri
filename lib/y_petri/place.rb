# encoding: utf-8

require_relative 'place/guard'
require_relative 'place/guarded'
require_relative 'place/arcs'

# Represents a Petri net place.
# 
class YPetri::Place
  ★ NameMagic                        # ★ means include
  ★ Arcs
  ★ Guarded
  ★ YPetri::World::Dependency

  class << self
    ★ YPetri::World::Dependency
    private :new
  end

  delegate :world, to: "self.class"

  attr_reader :quantum
  attr_reader :guards
  attr_accessor :default_marking

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
  # +Quantum+ attribute is not in use presently. In the future, it will be used
  # to decide when to switch between continuous and discrete stochastic modeling
  # of a place value. +Guard+ means a restriction of the place marking. (For
  # example, the place could only admit non-negative numbers, or numbers smaller
  # than 1, or odd numbers etc.) Named argument :guard along with a block
  # supplied to the constructor allow one to specify a single marking guard
  # upon place initialization by putting an NL assertion (a string) under
  # +:guard+ argument, along with a block expressing the same meaning in code.
  # More guards, if necessary, can be specified later using +Place#guard+ method.
  # 
  # If no guard block is supplied, default guards are constructed based on the
  # data type of the +:marking+ or +:default_marking+ argument. If it is wished
  # that the place has no guards whatsoever, +:guard+ argumend should be set to
  # _false_.
  # 
  def initialize quantum: 1,
                 default_marking: nil,
                 marking: nil,
                 guard: L!,
                 &block
    @upstream_arcs, @downstream_arcs, @guards = [], [], [] # init to empty
    @quantum, @default_marking = quantum, default_marking
    self.marking = marking || default_marking
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

  # Getter of the place's +@marking+ attribute.
  # 
  def m
    @marking
  end
  alias value m

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
    @marking = guard.( @default_marking )
  end

  # Builds an inspect string of the place.
  # 
  def inspect
    n, m, d, q = instance_description_strings
    "#<Place: #{ ( [n, m, d, q].compact ).join ', ' }>"
  end

  # Returns a string representing the place.
  # 
  def to_s
    n, m = name, marking
    "#{n.nil? ? 'Place' : n}[#{m.nil? ? 'nil' : m}]"
  end

  private

  def instance_description_strings
    m, n, d, q = marking, name, default_marking, quantum
    nς = "name: #{n.nil? ? '∅' : n}"
    mς = "marking: #{m.nil? ? 'nil' : m}"
    dς = "default_marking: #{d.nil? ? '∅' : d}"
    qς = q == 1 ? nil : "quantum: #{q.nil? ? '∅' : q}"
    return nς, mς, dς, qς
  end
end # class YPetri::Place
