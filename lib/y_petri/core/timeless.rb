# encoding: utf-8

# Timeless simulation core.
# 
class YPetri::Core
  class Timeless < YPetri::Core
    require_relative 'timeless/pseudo_euler'

    alias delta delta_timeless
    alias Δ delta
  end # class Timeless
end # class YPetri::Core
