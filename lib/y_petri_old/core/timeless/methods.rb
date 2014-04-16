# encoding: utf-8

# Timed simulation core.
# 
module YPetri::Core::Timeless
  require_relative 'pseudo_euler'

  module Methods
    def method_init
      extend case simulation_method
             when :pseudo_euler then PseudoEuler
             else fail TypeError, "Unknown timeless simulation method: #{method}!" end
    end
  end
end
