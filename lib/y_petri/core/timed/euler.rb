# encoding: utf-8

# Euler method.
# 
class YPetri::Core::Timed
  module Euler
    # Name of this method.
    # 
    def simulation_method
      :euler
    end

    # Computes Δ for the period of Δt.
    # 
    def delta Δt
      gradient * Δt
    end
    alias Δ delta
  end # Euler
end # YPetri::Core::Timed
