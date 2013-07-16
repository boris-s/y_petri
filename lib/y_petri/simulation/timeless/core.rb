# encoding: utf-8

# A timeless simulation method class.
# 
module YPetri::Simulation::Timeless
  class Core < YPetri::Simulation::Core
    require_relative 'core/pseudo_euler.rb'

    alias delta delta_timeless
    alias Δ delta
  end
end
