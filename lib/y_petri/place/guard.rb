# encoding: utf-8

# Marking guard of a place.
# 
class YPetri::Place::Guard
  # Error message template.
  # 
  ERRMSG = -> m, of, assert do
    "Marking #{m.insp}" +
      if of then " of #{of.name || of}" else '' end +
      " #{assert}!"
  end

  attr_reader :place, :assertion, :block

  # Expects a guard assetion in natural language, and a guard block. Guard block
  # is a unary block that validates marking. A validation fails when:
  #
  # 1. The block returns _false_.
  # 2. The block raises +YPetri::GuardError+.
  #
  # In all other cases, including when the block returns _nil_ (beware!),
  # the marking is considered valid. Inside the block, +#fail+ keyword is
  # redefined, so that it can (and must) be called without arguments, and it
  # raises an appropriately worded +GuardError+. (Other exceptions can still be
  # raised using +#raise+ keyword.) Practical example:
  # 
  #   YPetri::Place::Guard.new "should be a number" do |m|
  #     fail unless m.is_a? Numeric
  #   end
  #
  # Then <code>guard! :foobar</code> raises +GuardError+ with a message "Marking
  # foobar:Symbol should be a number!"
  # 
  def initialize( assertion_NL_string, place: nil, &block )
    @place, @assertion, @block = place, assertion_NL_string, block
    @Lab = Class.new BasicObject do
      def initialize λ; @λ = λ end
      def fail; @λ.call end
    end
  end

  # Validates a marking value. Raises +YPetri::GuardError+ upon failure.
  # 
  def validate( marking )
    λ = __fail__( marking, assertion )
    λ.call if @Lab.new( λ ).instance_exec( marking, &block ) == false
    return true
  end

  private

  # Constructs the fail closure.
  # 
  def __fail__ marking, assertionq
    pl = place
    -> { fail YPetri::GuardError, ERRMSG.( marking, pl, assertion ) }
  end
end
