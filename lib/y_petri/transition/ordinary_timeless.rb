# -*- coding: utf-8 -*-

# Mixin for timed non-assignment timeless Petri net transitions.
# 
module YPetri::Transition::OrdinaryTimeless
  # Result of the transition's "function", regardless of the #enabled? status.
  # 
  def action
    if stoichiometric? then
      rslt = action_closure.( *domain_marking )
      stoichiometry.map { |coeff| rslt * coeff }
    else
      action_closure.( *domain_marking )
    end
  end # action

  # Fires the transition, honoring cocking. Returns true if the transition
  # fired, false if it wasn't cocked.
  # 
  def fire
    cocked?.tap { |x| ( uncock; fire! ) if x }
  end

  # Fires the transition regardless of cocking.
  # 
  def fire!
    try "to call #fire method" do
      act = note "action", is: Array( action )
      codomain.each_with_index do |codomain_place, i|
        note "adding action element no. #{i} to place #{codomain_place}"
        codomain_place.add( note "marking change", is: act.fetch( i ) )
      end
    end
    return nil
  end

  # Timeless transition is _enabled_ if its action would result in a legal
  # codomain marking.
  # 
  def enabled?
    codomain.zip( action ).all? do |place, change|
      begin; place.guard.( place.marking + change )
      rescue YPetri::GuardError; false end
    end
  end
end # class YPetri::Transition::OrdinaryTimeless
