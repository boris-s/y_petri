# encoding: utf-8

# A mixin to make a place support guards.
# 
module YPetri::Place::Guarded
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
    if block then
      @guards << YPetri::Place::Guard.new( *args, place: name || self, &block )
    elsif args.size == 1 then
      federated_guard_closure.( args[0] )
    elsif args.empty? then
      federated_guard_closure
    end
  end

  # Returns a joint guard closure, composed of all the guards defined for the
  # place at the moment. Joint closure passes if and only if all the guard
  # blocks pass for the given marking value.
  # 
  def federated_guard_closure
    place_name, lineup = name.to_s, guards.dup
    -> m { lineup.each { |g| g.validate( m ) }; return m }
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
    case reference_marking
    when Complex then marking "should be Numeric" do |m| m.is_a? Numeric end
    when Numeric then
      marking "should be Numeric" do |m| m.is_a? Numeric end
      marking "should not be complex" do |m| fail if m.is_a? Complex end
      marking "should not be negative" do |m| m >= 0 end
    when nil then # no guards
    when true, false then marking "should be Boolean" do |m| m == !!m end
    else
      reference_marking.class.tap do |klass|
        marking "should be a #{klass}" do |m| m.is_a? klass end
      end
    end
    return nil
  end
end # module YPetri::Place::Guarded
