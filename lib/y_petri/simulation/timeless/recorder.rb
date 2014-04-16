module YPetri::Simulation::Timeless
  # Timeless recorder.
  # 
  class Recorder < YPetri::Simulation::Recorder
    attr_reader :next_event

    # Like +YPetri::Simulation::Recording#reset+, but allowing for additional
    # named argument +:next_event+ that sets the event (label, hash key) of
    # the next sample.
    # 
    def reset! next_event: 0, **named_args
      super.tap { @next_event = next_event }
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
