# As the name suggests, represents the world. Holds places, transitions, nets
# and other assets needed to set up and simulate Petri nets (settings, clamps,
# initial markings etc.). Provides basic methods to do what is necessary.
# More ergonomic and DSL-like methods are up to the YPetri::Agent.
# 
class YPetri::World
  include NameMagic

  require_relative 'world/dependency'
  require_relative 'world/petri_net_related'
  require_relative 'world/simulation_related'

  include self::PetriNetRelated
  include self::SimulationRelated

  def initialize
    # Parametrized subclasses of Place, Transition and Net.
    @Place = YPetri::Place.parametrize( world: self )
    @Transition = YPetri::Transition.parametrize( world: self )
    @Net = YPetri::Net.parametrize( world: self )
    # Make them their own namespaces.
    [ @Place, @Transition, @Net ].each &:namespace!
    # And proceeed as usual.
    super
  end
end
