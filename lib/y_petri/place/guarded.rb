# encoding: utf-8

# Support of places' marking guards.
# 
module YPetri::Place::Guarded
  # Expects a guard assertion in natural language, and a guard block. Guard
  # block is a unary block that validates marking. A validation fails when:
  # 
  # 1. The block returns _false_.
  # 2. The block raises +YPetri::GuardError+.
  # 
  # In all other cases, including when the block returns _nil_ (beware!),
  # the marking is considered valid! Inside the block, +#fail+ keyword is
  # redefined so that it can (and must) be called without arguments, and it
  # raises an appropriately worded +GuardError+. (Other exceptions can still
  # be raised using +#raise+ keyword.) Practical example:
  # 
  #   guard "should be a number" do |m| fail unless m.is_a? Numeric end
  # 
  # Then <code>guard! :foobar</code> raises +GuardError+ with a message "Marking
  # foobar:Symbol should be a number!"
  # 
  # Finally, this method is overloaded in such way, that if no block is
  # given to it, it acts as an alias of +#common_guard_closure+ method.
  # 
  def guard *args, &block
    if block then
      @guards << YPetri::Place::Guard.new( *args, place: self, &block )
    elsif args.size == 1 then
      common_guard_closure.( args[0] )
    elsif args.empty? then
      common_guard_closure
    end
  end

  # Returns a closure combining all the guards defined for the place so far,
  # which passes if, and only if, all the included guards pass. The common
  # closure, if it passes, returns the tested marking value.
  # 
  def common_guard_closure
    place_name, lineup = name.to_s, guards.dup
    -> marking { lineup.each { |g| g.validate marking }; marking }
  end

  # Applies the guards defined for the place on the current marking (contents
  # of +@marking+ instance variable).
  # 
  def guard!
    guard.( marking )
  end

  private

  # If no guards were specified by the user, this method can construct standard
  # guards based on the data type of places' +marking+ and/or +default_marking+.
  # (For most data types, default guards enfore type compliance. Numeric
  # descendants, however, are considered interchangeable, except for Complex
  # class.)
  # 
  def add_default_guards!( reference_marking )
    case reference_marking
    when Complex then # 1 guard
      marking "should be Numeric" do |m| m.is_a? Numeric end
    when Numeric then # 3 guards
      marking "should be Numeric" do |m| m.is_a? Numeric end
      marking "should not be complex" do |m| fail if m.is_a? Complex end
      marking( "should not be negative" ) { |m| m >= 0 } if
        reference_marking >= 0
    when nil then # no guards
    when true, false then # 1 guard
      marking "should be Boolean" do |m| m == !!m end
    else # 1 guard
      reference_marking.class.tap do |klass|
        marking "should be a #{klass}" do |m| m.is_a? klass end
      end
    end
    return nil
  end
end # module YPetri::Place::Guarded
