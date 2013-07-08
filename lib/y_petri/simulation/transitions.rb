#encoding: utf-8

require_relative 'transitions/types'
require_relative 'transitions/a'
require_relative 'transitions/A'
require_relative 'transitions/t'
require_relative 'transitions/T'
require_relative 'transitions/s'
require_relative 'transitions/S'
require_relative 'transitions/ts'
require_relative 'transitions/Ts'
require_relative 'transitions/tS'
require_relative 'transitions/TS'

# Transition collection for YPetri::Simulation.
#
class YPetri::Simulation::Transitions
  include Types

  # Pushes a transition to the collection.
  # 
  def push transition
    t = begin
          net.transition( transition )
        rescue NameError, TypeError
          return super transition( transition )
        end
    return super Transition().new( t, name: t.name ) if t.name
    super Transition().new( t )
  end
end # class YPetri::Simulation::Transitions
