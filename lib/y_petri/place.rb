# encoding: utf-8

require_relative 'place/guard'
require_relative 'place/arcs'

# Represents a Petri net place.
# 
class YPetri::Place
  include NameMagic
  include YPetri::World::Dependency

  class << self
    include YPetri::World::Dependency
  end

  delegate :world, to: "self.class"

  attr_reader :quantum
  attr_reader :guards
  attr_accessor :default_marking

  # Named parameters supplied upon place initialization may include:
  # 
  # * :marking
  # * :default_marking
  # * :quantum
  # * :guard
  # 
  # Those familiar with Petri nets need no introduction into _marking_
  # attribute of a Petri net place. However, _quantum_ is a relatively uncommon
  # concept in the context of Petri nets. +YPetri+ introduces quantum as a
  # replacement for the hybrid-ness of Hybrid Functional Petri Nets (HFPNs).
  # Formally, +YPetri+ is a discrete functional Petri net (FPN). The quantum
  # is a numeric representation of a token: The smallest number by which the
  # numeric representation of the place's marking can change. This is intended
  # to enable smooth transition between continuous and stochastic simulation
  # depending on pre-defined statistical settings.
  #
  # The :guard named argument and optional block specification allows to specify
  # one marking guard already upon place initialization. This is done by putting
  # the NL assertion string of the guard  under the :guard named argument, and
  # supplying the guard block to the constructor. More guards can be defined
  # later for the place using its +#guard+ method.
  # 
  # If no guard block is supplied, default guards are constructed based on the
  # type of the marking or default marking supplied upon initialization. For
  # numeric marking except complex numbers, the default type guard allows all
  # +Numeric+ types except complex numbers, and the default value guard prohibits
  # negative values. For all other classes, there is just one guard enforcing
  # the class compliance of the marking.
  #
  # To construct a place with no guards whatsoever, set :guard named argument
  # to _false_.
  # 
  def initialize quantum: 1,
                 default_marking: nil,
                 marking: nil,
                 guard: L!,
                 &block
    @upstream_arcs, @downstream_arcs, @guards = [], [], [] # init to empty
    @quantum, @default_marking = quantum, default_marking
    self.marking = marking || default_marking

    # Check in :guard named argument and &block.
    if guard.ℓ? then # guard NL assertion not given, use block or default guards
      block ? guard( &block ) : add_default_guards!( @marking )
    elsif guard then # guard NL assertion given
      fail ArgumentError, "No guard block given!" unless block
      guard( guard, &block )
    else
      fail ArgumentError, "Block given, but :guard set to falsey!" if block
    end
  end

  # Getter of +@marking+ attribute.
  # 
  def m; @marking end
  alias value m

  # This method, which acts as a simple getter of +@marking+ attribute if no
  # block is supplied to it, is overloaded to act as +#guard+ method frontend
  # if a guard block is supplied. The reason is because this
  #
  #   marking "should be a number" do |m| fail unless m.is_a? Numeric end
  # 
  # reads better than
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
  def value=( marking ); self.marking = marking end

  # Alias for #marking=
  # 
  def m=( marking ); self.marking = marking end

  # Adds tokens to the place.
  # 
  def add( amount )
    @marking = guard.( @marking + amount )
  end

  # Subtracts tokens from the place.
  # 
  def subtract( amount )
    @marking = guard.( @marking - amount )
  end

  # Resets place marking back to its default marking.
  # 
  def reset_marking
    @marking = guard.( @default_marking )
  end

  # Produces the inspect string of the place.
  # 
  def inspect
    n, m, d, q = instance_description_strings
    "#<Place: #{ ( [n, m, d, q].compact ).join ', ' }>"
  end

  # Returns a string briefly describing the place.
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
