# -*- coding: utf-8 -*-

# Guard mechanics aspect of a place.
# 
class YPetri::Place
  # Marking guard.
  # 
  class Guard
    ERRMSG = -> m, assert { "Marking #{m}:#{m.class} #{assert}!" }

    attr_reader :assertion, :block

    # Requires a NL guard assertion (used in GuardError messages), and a guard
    # block expressing the same assertion formally, in code.  Attention: *Only
    # _false_ result is considered a failure! If the block returns _nil_, the
    # guard has passed!* When +YPetri::Guard+ is in action (typically via its
    # +#validate+ method), it raises +YPetri::GuardError+ if the guard block
    # returns _false_. However, the guard block is welcome to raise +GuardError+
    # on its own, and for this purpose, it is evaluated inside a special "Lab"
    # object, with +#fail+ method redefined so as to accept no arguments, and
    # automatically raise appropriately worded +GuardError+. See also:
    # {+YPetri#guard+ method}[rdoc-ref:YPetri::guard].
    # 
    def initialize assertion_NL_string, &block
      @assertion, @block = assertion_NL_string, block
      @Lab = Class.new BasicObject do
        def initialize λ; @λ = λ end
        def fail; @λ.call end
      end
    end

    # Validates a supplied marking value against the guard block. Raises
    # +YPetri::GuardError+ if the guard fails, otherwise returns _true_.
    # 
    def validate( marking_value )
      λ = __fail__( marking_value, assertion )
      λ.call if @Lab.new( λ ).instance_exec( marking_value, &block ) == false
      return true
    end

    private

    # Constructs the fail closure.
    # 
    def __fail__ marking_value, assertion
      -> { fail YPetri::GuardError, ERRMSG.( marking_value, assertion ) }
    end
  end

  # Expects a guard assertion in natural language, and a guard block. Guard
  # block is a unary block capable of validating a marking value. The validation
  # is considered as having failed if:
  #
  # 1. The block returns _false_.
  # 2. The block raises +YPetri::GuardError+.
  #
  # In all other cases, including the block returning _nil_, the validation is
  # considered as having passed! The block is evaluated in the context of a
  # special "Lab" object, which has +#fail+ method redefined so that it can
  # (and must) be called without parameters, and produces an appropriately
  # worded +GuardError+. (Other exceptions can be still raised using +#raise+
  # method.)
  # 
  # As for the NL assertion, apart from self-documenting the code, it is used
  # for constructing appropriately worded +GuardError+ messages:
  #
  #   guard "should be a number" do |m| fail unless m.is_a? Numeric end
  #
  # Then +guard! :foobar+ raises +GuardError+ with message "Marking foobar:Symbol
  # should be a number!"
  #
  # The method returns the reference to the +YPetri::Guard+ object, that has
  # been constructed and already included in the collection of this place's
  # guards.
  #
  # Finally, this method is overloaded in such way, that if no block is
  # given to it, it acts as a frontend for the +#federated_guard_closure+
  # method: It either applies the federated closure to the marking value given
  # in the argument, or returns the federated closure itself if no arguemnts
  # were given (behaving as +#federated_guard_closure+ alias in this case).
  # 
  def guard *args, &block
    if block then @guards << Guard.new( *args, &block )
    elsif args.size == 1 then federated_guard_closure.( args[0] )
    elsif args.empty? then federated_guard_closure
    end
  end

  # Returns a joint guard closure, composed of all the guards defined for the
  # place at the moment. Joint closure passes if and only if all the guard
  # blocks pass for the given marking value.
  # 
  def federated_guard_closure
    lineup = guards.dup
    -> marking_value { lineup.each { |g| g.validate marking_value }; true }
  end

  # Applies guards on the marking currently owned by the place.
  # 
  def guard!
    guard.( marking )
  end

  private

  # If no guards were specified by the user, this method can make them up in a
  # standard way, using user-supplied marking / default marking as a type
  # reference. Numeric types are an exception – they are considered mutually
  # interchangeable, except complex numbers.
  # 
  def add_default_guards!( reference_marking )
    ref_class = reference_marking.class
    if ref_class < Numeric and not ref_class < Complex then
      # Note that #marking method is overloaded to act as #guard method when
      # a block is supplied to it:
      marking "should be a number" do |m| m.is_a? Numeric end
      marking "should not be complex" do |m| fail if m.is_a? Complex end
    else
      marking "should be a #{ref_class}" do |m| m.is_a? ref_class end
    end
  end
end # class YPetri::Place
