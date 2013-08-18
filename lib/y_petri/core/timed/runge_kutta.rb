# encoding: utf-8

# Gillespie method.
# 
module YPetri::Core::Timed::Euler
  # Name of this method.
  # 
  def simulation_method
    :runge_kutta
  end

  # FIXME

  # This is from Euler:

  # # Computes Δ for the period of Δt.
  # # 
  # def delta Δt
  #   gradient * Δt
  # end
  # alias Δ delta
end # YPetri::Core::Timed::Euler
