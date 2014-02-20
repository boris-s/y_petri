module YPetri::Simulation::Timeless
  # A timeless recorder.
  # 
  class Recorder < YPetri::Simulation::Recorder
    attr_reader :next_event

    # Like +YPetri::Simulation::Recording#reset+, but allowing for additional
    # named argument +:next_sample+ that sets the event (label, hash key) of
    # the next sample.
    # 
    def reset! **nn
      super.tap { @next_event = nn[:next_event] || 0 }
    end

    # Backsteps the simulation.
    # 
    def back!
      fail NotImplementedError, "Backstep for timeless simulation not done yet!"
    end
    
    private

    # Records the current system state under a numbered sample.
    # 
    def sample!
      super next_event
      @next_event = @next_event.next # "event" shoud implement next method
    end
  end # class Recorder
end # YPetri::Simulation::Timeless
