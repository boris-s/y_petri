# encoding: utf-8

# Runge-Kutta method. Like vanilla Euler method, assumes that only T transitions are in the net.
# 
module YPetri::Core::Timed::RungeKutta
  def delta Δt
    fail NotImplementedError, "RungeKutta not implemented yet!"
    # Of course, the following line is from Euler method.
    # The formula of Runge-Kutta is more complicated.
    # 
    gradient * Δt
  end
  alias Δ delta
end # YPetri::Core::Timed::RungeKutta
