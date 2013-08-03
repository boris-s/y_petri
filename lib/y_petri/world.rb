# encoding: utf-8

require_relative 'world/dependency'
require_relative 'world/petri_net_related'
require_relative 'world/simulation_related'


# As the name suggests, represents the world. Holds places, transitions, nets
# and other assets needed to set up and simulate Petri nets (settings, clamps,
# initial markings etc.). Provides basic methods to do what is necessary.
# More ergonomic and DSL-like methods are up to the YPetri::Agent.
# 
class YPetri::World
  ★ NameMagic                        # ★ means include
  ★ PetriNetRelated
  ★ SimulationRelated

  def initialize
    # Parametrize the Place / Transition / Net classes.
    param_class!( { Place: YPetri::Place,
                    Transition: YPetri::Transition,
                    Net: YPetri::Net },
                  with: { world: self } )
    # Make them their own namespaces.
    [ Place(), Transition(), Net() ].each &:namespace!
    # And proceeed as usual.
    super
  end
end
