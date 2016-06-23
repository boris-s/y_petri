# encoding: utf-8

# Mixin for the transitions with assignment action.
# 
module YPetri::Transition::Type_A
  # For assignment transitions, "function" refers to their action closure.
  # 
  def function
    action_closure
  end

  # Transition's action (before validation).
  # 
  def action
    action_closure.( *domain_marking )
  end

  # Applies action to the codomain, honoring cocking. Returns true if the transition
  # fired, false if it wasn't cocked.
  # 
  def fire
    cocked?.tap { |x| ( uncock; fire! ) if x }
  end

  # Assigns the action closure result to the codomain, regardless of cocking.
  # 
  def fire!
    act = Array( action )
    fail TypeError, "Wrong output arity of the action " +
      "closure of #{self}" if act.size != codomain.size
    codomain.each_with_index { |place, index|
      # assigning action node no. index to place
      place.marking = act.fetch( index )
    }
    return nil
  end

  # A transitions are always _enabled_.
  # 
  def enabled?
    true
  end

  # Transition's assignment action under current simulation.
  # 
  def a simulation=world.simulation
    simulation.net.State.Feature.Assignment( self ) % simulation
  end
end # class YPetri::Transition::Type_A
