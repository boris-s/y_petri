# encoding: utf-8

# Timed simulation -- recording.
# 
module YPetri::Simulation::Timed
  class Core
    # Euler method.
    # 
    module Euler
      # Name of this method.
      # 
      def method
        :euler
      end

      # Computes Δ for the period of Δt.
      # 
      def delta Δt
        gradient * Δt
      end
      alias Δ delta
    end
  end
end
