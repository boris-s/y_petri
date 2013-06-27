# -*- coding: utf-8 -*-

# Mixin for the transitions with assignment action.
# 
module YPetri::Transition::Assignment
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
    try "to call #fire! method" do
      act = note "action", is: Array( action )
      codomain.each_with_index do |codomain_place, i|
        note "assigning action element no. #{i} to place #{codomain_place}"
        codomain_place.marking = note "marking to assign", is: act.fetch( i )
      end
    end
    return nil
  end

  # A transitions are always _enabled_.
  # 
  def enabled?
    true
  end
end # class YPetri::Transition::Assignment
