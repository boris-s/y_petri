#encoding: utf-8

# Workspace holds places, transitions, nets and other assets needed for
# simulation (settings, clamps, initial markings etc.). Workspace also
# provides basic methods for their handling, but these are not too public.
# YPetri interface is defined by YPetri::Manipulator.
# 
class YPetri::Workspace
  include NameMagic

  require_relative 'workspace/instance_methods'
  require_relative 'workspace/parametrized_subclassing'

  include self::InstanceMethods
  prepend self::ParametrizedSubclassing
end
