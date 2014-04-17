# encoding: utf-8

# Euler method. Assumes that only T transitions are in the net.
# 
module YPetri::Core::Timed::Euler
  # Computes Δ for the period of Δt. Since this method assumes that only
  # timed transitions are in the net, delta state is computed simply bu
  # multiplying the gradient by Δt.
  # 
  def delta Δt
    gradient * Δt
  end
  alias Δ delta
end # YPetri::Core::Timed::Euler
