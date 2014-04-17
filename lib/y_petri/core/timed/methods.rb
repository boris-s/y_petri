# encoding: utf-8

# Timed simulation core.
# 
module YPetri::Core::Timed
  require_relative 'euler'
  require_relative 'pseudo_euler' # t transitions firing after each step
  require_relative 'quasi_euler' # t transitions firing after each time tick
  require_relative 'gillespie'
  require_relative 'runge_kutta'

  module Methods
    def method_init
      extend case simulation_method
             when :euler then Euler
             when :pseudo_euler then PseudoEuler
             when :quasi_euler then QuasiEuler
             when :gillespie then Gillespie
             when :runge_kutta then RungeKutta
             else fail TypeError, "Unknown timed simulation method: #{method}!" end
    end
  end
end
