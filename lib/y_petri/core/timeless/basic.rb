# encoding: utf-8

# The basic simulation method in YPetri is simple Petri net (PN) execution. While
# in principle applicable to any PN type, it can be made slightly more efficient
# if it is known in advance that no no timed transitions will be in the net.
#
module YPetri::Core::Timeless::Basic
  # Peforms a single step of the basic method.
  # 
  def step!
    # Compute the sum of the contribution of ts and tS transitions, and
    # increment the free marking vector by it.
    increment_free_vector by: delta_ts + delta_tS
    # Fire all the assignment transitions in their order.
    fire_all_assignment_transitions!
    # before: assignment_transitions_all_fire!
    # Alert the recorder(s) that the system has changed.
    alert!
  end
end # module YPetri::Core::Timeless::Basic
