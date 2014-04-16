# encoding: utf-8

# A mixin for timed transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_t
    include Type_a

    # False for timed transitions.
    # 
    def T?
      false
    end
    alias timed? T?

    # True for timed transitions.
    # 
    def t?
      true
    end
    alias timeless? t?

    # Initialization subroutine.
    # 
    def init
      super
      @function = source.action_closure
    end

    # Change, as it would happen if the transition fired, returned as hash
    # codomain places >> change.
    # 
    def d
      delta.with_keys do |p| p.name || p end
    end
  end # Type_t
end # class YPetri::Simulation::TransitionRepresentation
