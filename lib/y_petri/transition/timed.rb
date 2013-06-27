# -*- coding: utf-8 -*-

# Mixin for timed Petri net transitions.
# 
module YPetri::Transition::Timed
  # Transition's action (before validation). Requires Δt as an argument.
  # 
  def action Δt
    if has_rate? then
      if stoichiometric? then
        rate = rate_closure.( *domain_marking )
        stoichiometry.map { |coeff| rate * coeff * Δt }
      else # assuming that rate closure return value has correct arity
        rate_closure.( *domain_marking ).map { |e| component * Δt }
      end
    else # timed rateless
      if stoichiometric? then
        rslt = action_closure.( Δt, *domain_marking )
        stoichiometry.map { |coeff| rslt * coeff }
      else
        action_closure.( Δt, *domain_marking ) # caveat result arity!
      end
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
