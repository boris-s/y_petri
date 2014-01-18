# encoding: utf-8

class YPetri::Simulation
  # Transition collection for YPetri::Simulation.
  #
  class Transitions < Elements
    require_relative 'transitions/types'
    ★ Types # ★ means include

    # Pushes a transition to the collection.
    # 
    def push transition
      t = begin
            net.transition( transition )
          rescue NameError, TypeError
            return super transition( transition )
          end
      super t.name ? Transition().new( t, name: t.name ) : Transition().new( t )
    end
  end # class Transitions
end # class YPetri::Simulation::Transitions
