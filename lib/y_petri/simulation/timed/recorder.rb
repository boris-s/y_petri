module YPetri::Simulation::Timed
  # Timed aspect of the recorder.
  #
  class Recorder < YPetri::Simulation::Recorder
    TIME_DECIMAL_PLACES = 5

    attr_reader :next_time
    attr_accessor :sampling
    delegate :time, to: :simulation

    # Like +YPetri::Simulation::Recorder#reset+, but allowing for an additional
    # named argument +:next_time+ that sets the next sampling time, and
    # +:sampling:, resetting the sampling period.
    # 
    def reset! sampling: simulation.default_sampling, next_time: time, **nn
      super
      @sampling = sampling
      @next_time = next_time
    end

    # Hook to be called by simulators whenever the state changes (every time
    # that simulation +time+ is incremented).
    # 
    def alert
      t = time.round( 9 )
      t2 = next_sampling_time.round( 9 )
      if t >= t2 then # it's time to sample
        sample!
        @next_time += sampling
      end
    end

    private

    # Records the current state as a pair { sampling_time => system_state }.
    # 
    def sample! time
      sampling_time = time.round( TIME_DECIMAL_PLACES )
      super sampling_time
    end
  end # class Recorder
end # YPetri::Simulation
