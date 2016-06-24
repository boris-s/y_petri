# encoding: utf-8

# Mixin for timed Petri net transitions.
# 
module YPetri::Transition::Type_T
  # For timed transitions, "function" refers to their rate closure.
  # 
  def function
    rate_closure
  end

  # Transition's action (before validation). Requires Δt as an argument.
  #
  def action Δt
    # TODO: Unhelpful error occurs if the user constructs a transition
    # like this:
    #
    #   T = Transition s: { A: -1, B: 2 },
    #                  rate: -> { 0.1 }    # constant rate
    #
    # The user meant to construct a TS transition with constant rate and
    # stoichiometry { A: -1, B: 2 }, but the lambda given under :rate
    # parameter is nullary, while the stoichiometry is taken to imply that
    # the domain consists of place 1.
    #
    #   T.action 5.0
    #
    # then causes error because it tries to supply the marking of A to
    # the user-supplied rate closure, which is nullary.
    #
    # There are 2 problems with this:
    #
    # Firstly, if we choose to see this as the user's problem, the user
    # supplied the Transition constructor with invalid input, but received
    # no warning (problem 1). The user learned about the error by typing
    # T.action 5.0, and the error message is quite unhelpful (problem 2) -
    # it does not inform the user that the rate closure has wrong arity.
    #
    # We, we might deside to see this as a missing feature and make sure
    # that in these cases, the constructor infers that the codomain is
    # empty from the fact that the supplied rate closure is nullary. This
    # requires additional thinking, because it is not possible to infer
    # domain from rate lamdas with non-matching arity in general.
    # 
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
