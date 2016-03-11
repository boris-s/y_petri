# encoding: utf-8

# The basic simulation method in YPetri is simple Petri net (PN) execution. While
# in principle applicable to any PN type, it can be made slightly more efficient
# if it is known in advance that no no timed transitions will be in the net.
#
module YPetri::Core::Timeless::Basic
  # Computes Δ for the simulation step.
  # 
  def delta Δt
    delta_timeless # This method, defined in module core.rb, simply presents
                   # the contribution to free places by timeless transitions.
  end
  alias Δ delta
  
  # Peforms a single step of the basic method.
  # 
  def step!
    # Compute the sum of the contribution of ts and tS transitions, and
    # increment the free marking vector by it.
    increment_free_vector by: Δ
    # Fire all the assignment transitions in their order.
    fire_all_assignment_transitions!
    # before: assignment_transitions_all_fire!
    # Alert the recorder(s) that the system has changed.
    alert!
  end
end # module YPetri::Core::Timeless::Basic
