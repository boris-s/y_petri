# -*- coding: utf-8 -*-

# Mixin for timed Petri net transitions.
# 
module YPetri::Transition::Timed
  # Transition's action (before validation). Requires Δt as an argument.
  # 
  def action Δt
    if stoichiometric? then
      rate = rate_closure.( *domain_marking )
      stoichiometry.map { |coeff| rate * coeff * Δt }
    else
      rate_closure.( *domain_marking ).map { |e| e * Δt }
    end
  end

  # Fires the transition, honoring cocking. Returns true if the transition
  # fired, false if it wasn't cocked.
  # 
  def fire Δt
    cocked?.tap { |x| ( uncock; fire! Δt ) if x }
  end

  # Fires the transition regardless of cocking. For timed transitions, takes
  # Δt as an argument.
  # 
  def fire! Δt
    try "to call #fire method" do
      act = note "action", is: Array( action Δt )
      codomain.each_with_index do |codomain_place, i|
        note "adding action element no. #{i} to place #{codomain_place}"
        codomain_place.add( note "marking change", is: act.fetch( i ) )
      end
    end
    return nil
  end

  # YPetri transitions are _enabled_ if and only if the intended action would
  # lead to a legal codomain marking. For timed transitions, +#enabled?+ method
  # takes Δt as an argument.
  # 
  def enabled? Δt
    codomain.zip( action Δt ).all? do |place, change|
      begin; place.guard.( place.marking + change )
      rescue YPetri::GuardError; false end
    end
  end
end # class YPetri::Transition::Timed
