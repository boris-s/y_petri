# encoding: utf-8

# Timeless simulator mixin.
# 
module YPetri::Core::Timeless
  require_relative 'timeless/methods'
  ★ Methods

  # Makes a single step.
  # 
  def delta
    delta_timeless
  end

  # Computes the system state delta.
  # 
  def Δ
    delta
  end
end # module YPetri::Core::Timeless
