# encoding: utf-8

# Marking guard of a place.
# 
class YPetri::Place::Guard
  ERRMSG = -> m, of, assert do
    "Marking #{m}:#{m.class}" +
      if of then " of #{of.name || of rescue of}" else '' end +
      " #{assert}!"
  end

  attr_reader :place, :assertion, :block

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
  def initialize( assertion_NL_string, place: nil, &block )
    @place, @assertion, @block = place, assertion_NL_string, block
    @Lab = Class.new BasicObject do
      def initialize λ; @λ = λ end
      def fail; @λ.call end
    end
  end

  # Validates a supplied marking value against the guard block. Raises
  # +YPetri::GuardError+ if the guard fails, otherwise returns _true_.
  # 
  def validate( marking )
    λ = __fail__( marking, assertion )
    λ.call if @Lab.new( λ ).instance_exec( marking, &block ) == false
    return true
  end

  private

  # Constructs the fail closure.
  # 
  def __fail__ marking, assertion
    pl = place
    -> { fail YPetri::GuardError, ERRMSG.( marking, pl, assertion ) }
  end
end
