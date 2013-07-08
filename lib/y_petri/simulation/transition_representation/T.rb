#encoding: utf-8

# A mixin for timed transition representations.
# 
class YPetri::Simulation::TransitionRepresentation
  module Type_T
    include Type_a
    
    # True for timed transitions.
    # 
    def T?
      true
    end
    alias timed? T?
    
    # False for timed transitions.
    # 
    def t?
      false
    end
    alias timeless? t?
    
    # Initialization subroutine.
    # 
    def init
      super
      @function = source.rate_closure
    end
    
    # Gradient contribution of the transition to the free places.
    # 
    def gradient
      ∇.select { |p, v| p.free? }
    end
    
    # Returns the gradient contribution to the free places, as hash
    # place names >> gradient contribution.
    # 
    def g
      gradient.with_keys do |p| p.name || p end
    end
    
    # Returns the gradient contribution to all the places, as hash
    # place names >> gradient contribution.
    # 
    def g_all
      ∇.with_keys do |p| p.name || p end
    end
    
    # Change, for free places, as it would happen if the transition fired for
    # time Δt, returned as hash codomain places >> change.
    # 
    def delta Δt
      gradient.with_values { |v| v * Δt }
    end
    
    # Change, for free places, as it would happen if the transition fired for
    # time Δt, returned as hash codomain place names >> change.
    # 
    def d Δt
      delta( Δt ).with_keys do |p| p.name || p end
    end
    
    # Change, for all places, as it would happen if the transition fired for
    # time Δt, returned as hash codomain places >> change.
    # 
    def Δ( Δt )
      gradient.with_values { |v| v * Δt }
    end
    alias delta_all Δ
    
    # Change, for all places, as it would happen if the transition fired for
    # time Δt, returned as hash codomain place names >> change.
    # 
    def d_all( Δt )
      delta( Δt ).with_keys do |p| p.name || p end
    end
  end # Type_T
end # class YPetri::Simulation::TransitionRepresentation
