# encoding: utf-8

# Mixin for timed non-assignment timeless Petri net transitions.
# 
module YPetri::Transition::Type_t
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
    consciously "call #fire method" do
      act = Array( action )
      msg = "Wrong output arity of the action closure of #{self}!"
      fail TypeError, msg if act.size != codomain.size
      codomain.each_with_index do |p, i|
        note "adding action element no. #{i} to #{p}"
        p.add note( "marking change", is: act.fetch( i ) )
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

  # Transition's firing under current simulation.
  # 
  def fir simulation=world.simulation
    simulation.net.State.Feature.Firing( self ) % simulation
  end

  # Prints the transition's action under current simulation.
  # 
  def pa simulation=world.simulation, **nn
    ff = simulation.net.State.Features.Delta( codomain, transitions: self )
    ( ff >> ff % simulation ).pretty_print_numeric_values **nn
  end
end # class YPetri::Transition::Type_t
