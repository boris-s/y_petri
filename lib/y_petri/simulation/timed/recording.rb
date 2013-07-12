# Timed simulation -- recording.
# 
module YPetri::Simulation::Timed
  class Recording < YPetri::Simulation::Recording
    TIME_PRECISION = 5

    delegate :time, to: :simulation
    attr_accessor :next_sampling_time,
                  :sampling_period

    # Resets the recording.
    # 
    def reset!
      super
      @next_sampling_time = time
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
