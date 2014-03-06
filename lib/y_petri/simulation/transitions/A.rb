#encoding: utf-8

# A mixin for collections of A transitions.
# 
class YPetri::Simulation::Transitions
  module Type_A
    def initialize
    end

    # Assignment closures.
    # 
    def assignment_closures
      map &:assignment_closure
    end

    # Assignment closures that directly affect the marking when called.
    # 
    def direct_assignment_closures
      map &:direct_assignment_closure
    end

    # Combined assignment action, as it would occur if these A transitions fired
    # in order, as hash place >> action.
    # 
    def action
      each_with_object Hash.new do |t, hsh| hsh.update( t.action ) end
    end

    # Returns the assignments to all places, as they would happen if A transition
    # could change their values.
    # 
    def act
      each_with_object Hash.new do |t, hsh| hsh.update( t.act ) end
    end

    # Builds a joint assignment closure.
    # 
    def to_assignment_closure
      closures = assignment_closures
      -> { closures.each &:call }
    end
    alias assignment_closure to_assignment_closure

    # Builds a joint direct assignment closure, directly bound to the marking
    # vector and changing its values when called.
    # 
    def to_direct_assignment_closure
      closures = direct_assignment_closures
      -> { closures.each &:call }
    end
    alias direct_assignment_closure to_direct_assignment_closure
  end # Type_A
end # class YPetri::Simulation::Transitions
