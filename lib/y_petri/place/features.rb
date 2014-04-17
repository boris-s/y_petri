# encoding: utf-8

# Place instance methods concerned with state and/or simulation features.
# 
module YPetri::Place::Features
  # Expects an array of transitions, and +:net+ named argument. Returns a single
  # gradient feature belonging to the net for this place, and those upstream T
  # transitions, that are also in the included in the array. If no ordered
  # arguments are given, complete set of upstream T transitions is assumed. If
  # no +:net+ is given, +Top+ is assumed.
  # 
  def Gradient array, net: world.net( :Top )
    fail TypeError, "#{self} must be included in the net!" unless
      net.include? self
    transitions = upstream_arcs.select { |t| array.include? t }.select( &:T? )
    net.State.Feature.Gradient( self, transitions: transitions )
  end

  # Expects an arbitrary number of transitions, and +:net+ named argument.
  # Returns a single gradient feature belonging to the net for this place,
  # and those upstream T transitions, that are also in the included among
  # the arguments. If no ordered arguments are given, complete set of upstream
  # T transitions is assumed. If no +:net+ is given, +Top+ is assumed.
  # 
  def gradient *transitions, net: world.net( :Top )
    return Gradient upstream_arcs, net: net if transitions.empty?
    Gradient transitions, net: net
  end

  # Expects an array of transitions, and +:net+ named argument. Returns a
  # feature set belonging to the net, consisting of the features for this
  # place, and those upstream T transitions, that are also included in the
  # array. If no +:net+ is given, +Top+ is assumed.
  # 
  def Gradients array, net: world.net( :Top )
    fail TypeError, "#{self} must be included in the net!" unless
      net.include? self
    transitions = upstream_arcs.select { |t| array.include? t }.select( &:T? )
    net.State.Features( transitions.map { |t| gradient t, net: net } )
  end

  # Expects an arbitrary number of transitions, and +:net+ named argument.
  # Returns a feature set belonging to the net, constisting of the features
  # for this place, and those upstream T transitions, that are also included
  # in the array. If no ordered arguments are given, complete set of upstream
  # T transitions is assumed. If no +:net+ is given, +Top+ is assumed.
  # 
  def gradients *transitions, net: world.net( :Top )
    return Gradients upstream_arcs, net: net if transitions.empty?
    Gradients transitions, net: net
  end

  # Expects an array of transitions, and +:net+ named argument. Returns a single
  # delta feature belonging to the net for this place, and those upstream T
  # transitions, that are also in the included in the array. If no ordered
  # arguments are given, complete set of upstream T transitions is assumed. If
  # no +:net+ is given, +Top+ is assumed.
  # 
  def Delta array, net: world.net( :Top )
    fail TypeError, "#{self} must be included in the net!" unless
      net.include? self
    transitions = upstream_arcs.select { |t| array.include? t }.select( &:T? )
    net.State.Feature.Delta( self, transitions: transitions )
  end

  # Expects an arbitrary number of transitions, and +:net+ named argument.
  # Returns a single delta feature belonging to the net for this place,
  # and those upstream T transitions, that are also in the included among
  # the arguments. If no ordered arguments are given, complete set of upstream
  # T transitions is assumed. If no +:net+ is given, +Top+ is assumed.
  # 
  def delta *transitions, net: world.net( :Top )
    return Delta upstream_arcs, net: net if transitions.empty?
    Delta transitions, net: net
  end

  # Expects an array of transitions, and +:net+ named argument. Returns a
  # feature set belonging to the net, consisting of the features for this
  # place, and those upstream T transitions, that are also included in the
  # array. If no +:net+ is given, +Top+ is assumed.
  # 
  def Deltas array, net: world.net( :Top )
    fail TypeError, "#{self} must be included in the net!" unless
      net.include? self
    transitions = upstream_arcs.select { |t| array.include? t }.select( &:T? )
    net.State.Features( transitions.map { |t| delta t, net: net } )
  end

  # Expects an arbitrary number of transitions, and +:net+ named argument.
  # Returns a feature set belonging to the net, constisting of the features
  # for this place, and those upstream T transitions, that are also included
  # in the array. If no ordered arguments are given, complete set of upstream
  # T transitions is assumed. If no +:net+ is given, +Top+ is assumed.
  # 
  def deltas *transitions, net: world.net( :Top )
    return Deltas upstream_arcs, net: net if transitions.empty?
    Deltas transitions, net: net
  end

  # Convenience method. Prints gradients under curent simulation.
  # 
  def pg simulation=world.simulation, precision: 8, **nn
    ( gradients >> gradients % simulation )
      .pretty_print_numeric_values precision: precision, **nn
  end

  # Convenience method. Prints deltas under current simulation.
  # 
  def pd simulation=world.simulation, precision: 8, **nn
    nn.may_have :delta_time, syn!: :Δt
    delta_time = nn.delete( :delta_time ) || world.simulation.step
    ( deltas >> deltas % [ simulation, delta_time: delta_time ] )
      .pretty_print_numeric_values precision: precision, **nn
  end
end # class YPetri::Place::Features
