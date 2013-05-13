# Workspace holds places, transitions, nets and other assets needed to set up
# and simulate Petri nets (settings, clamps, initial markings etc.). Workspace
# provides basic, decent, vanilla methods to just do what is necessary. It is
# up to YPetri::Manipulator to provide ergonomical DSL to the user.
# 
class YPetri::Workspace
  include NameMagic

  require_relative 'workspace/petri_net_related_methods'
  require_relative 'workspace/parametrized_subclassing'
  require_relative 'workspace/simulation_related_methods'

  include self::PetriNetRelatedMethods
  prepend self::ParametrizedSubclassing
  include self::SimulationRelatedMethods
end
