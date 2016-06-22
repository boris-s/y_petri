# encoding: utf-8

# Mixin for timed Petri net transitions.
# 
module YPetri::Transition::Type_T
  # Transition's action (before validation). Requires Δt as an argument.
  # 
  def action Δt
    if stoichiometric? then
      rate = rate_closure.( *domain_marking )
      stoichiometry.map { |coeff| rate * coeff * Δt }
    else
      Array( rate_closure.( *domain_marking ) ).map { |e| e * Δt }
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
    action = Array( action Δt )
    fail TypeError, "Wrong output arity of the action " +
      "closure of #{self}!" if action.size != codomain.size
    codomain.each_with_index do |place, index|
      # Adding action place no. index to place"
      place.add action.fetch( index )
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

  # Transition's firing under current simulation.
  # 
  def fir simulation=world.simulation, **nn
    nn.must_have :delta_time, syn!: :Δt
    Δt = nn.delete( :delta_time ) || simulation.step
    simulation.net.State.Feature.Firing( self ) % [ simulation, Δt: Δt ]
  end

  # Transition's flux under current simulation.
  # 
  def f simulation=world.simulation
    simulation.net.State.Feature.Flux( self ) % simulation
  end

  # Prints the transition's action under current simulation.
  #
  def pa simulation=world.simulation, **nn
    nn.must_have :delta_time, syn!: :Δt
    Δt = nn.delete( :delta_time ) || simulation.step
    ff = simulation.net.State.Features.Delta( codomain, transitions: self )
    ( ff >> ff % simulation ).pretty_print_numeric_values( **nn )
  end
end # class YPetri::Transition::Type_T
