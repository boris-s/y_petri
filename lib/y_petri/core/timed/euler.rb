# encoding: utf-8

# Euler method.
# 
module YPetri::Core::Timed::Euler
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
end # YPetri::Core::Timed::Euler
