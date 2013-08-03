# -*- coding: utf-8 -*-

# Mixin for the transitions with assignment action.
# 
module YPetri::Transition::Type_A
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
    consciously "to #fire!" do
      act = note "action", is: Array( action )
      msg = "Wrong output arity of the action closure of #{self}"
      fail TypeError, msg if act.size != codomain.size
      codomain.each_with_index { |p, i|
        note "assigning action element no. #{i} to #{p}"
        p.marking = note "marking to assign", is: act.fetch( i )
      }
    end
    return nil
  end

  # A transitions are always _enabled_.
  # 
  def enabled?
    true
  end
end # class YPetri::Transition::Type_A
