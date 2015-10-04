# encoding: utf-8

require_relative 'world/dependency'
require_relative 'world/petri_net_aspect'
require_relative 'world/simulation_aspect'

# Represents YPetri workspace, but "world" is shorter. Its instance holds
# places, transitions, nets and other assets needed to perform the tasks
# of system specification and simulation (simulation settings, place clamps,
# initial markings etc.). Provides basic methods to do just what is necessary.
# More ergonomic and DSL-like methods may be defined in YPetri::Agent.
# 
class YPetri::World
  ★ NameMagic                        # ★ means include
  ★ PetriNetAspect
  ★ SimulationAspect

  def initialize
    # Set up parametrized subclasses of Place, Transition, Net.
    param_class!( { Place: YPetri::Place,
                    Transition: YPetri::Transition,
                    Net: YPetri::Net },
                  with: { world: self } )
    # Invoke #namespace! method (from YSupport's NameMagic) on each of them.
    # This causes each of them to do bookkeeping of their instances. This is
    # because there is little point in keeping the objects from separate
    # worlds (ie. workspaces) on the same list.
    [ Place(), Transition(), Net() ].each &:namespace!
    # And proceed with initializations (if any) higher in the lookup chain.
    super
  end
end
