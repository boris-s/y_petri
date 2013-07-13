# Timed simulation -- recording.
# 
module YPetri::Simulation::Timed
  class Recording < YPetri::Simulation::Recording
    TIME_PRECISION = 5

    delegate :time, to: :simulation
    attr_accessor :next_sampling_time,
                  :sampling_period

    # Like +YPetri::Simulation::Recording#reset+, allowing for additional named
    # argument +:next_time+ that sets the next sampling time.
    # 
    def reset! **nn
      super
      next_time = nn[:next_time] || time
      next_sampling_time = next_time
    end

    # Hook to allow Simulation to react to its state changes.
    # 
    def note_state_change
      if time.round( 9 ) >= next_sampling_time.round( 9 ) then
        sample! # !sample it the sampling time has passed
        @next_sampling_time += @sampling_period
      else nil end
    end

    # Records the current state as { time => system_state }.
    # 
    def sample!
      super time.round( TIME_PRECISION )
    end
  end
end
