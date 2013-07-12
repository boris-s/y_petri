# encoding: utf-8

# Timed simulation -- recording.
# 
module YPetri::Simulation::Timed
  class Method
    # Euler method.
    # 
    module Euler
      # Computes Δ for the period of Δt.
      # 
      def delta Δt
        gradient * Δt
      end
      alias Δ delta
    end
  end
end
