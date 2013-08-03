# encoding: utf-8

# Timeless simulation core.
# 
class YPetri::Core::Timeless < YPetri::Core
  require_relative 'timeless/pseudo_euler'

  def delta
    delta_timeless
  end

  def Δ
    delta
  end
end # class YPetri::Core::Timeless
