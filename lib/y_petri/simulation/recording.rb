# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  class Recording < Hash
    include DependencyInjection

    SAMPLING_DECIMAL_PLACES = 5

    # Without an argument, resets the recording to empty. With a named argument
    # +:recording+, resets the recording to a new specified recording.
    # 
    def reset! **nn
      clear
      new_recording = nn[:recording]
      update Hash[ new_recording ] unless new_recording.nil?
    end

    # Hook to be called by the simulation methods whenever the state changes.
    # Recording mechanics then takes care of the sampling.
    # 
    def note_state_change
      sample! # default for vanilla Simulation: sample! at every occasion
    end

    # Records the current state as a pair { sampling_event => system state }.
    # 
    def sample! event=nil
      @sample_number = @sample_number + 1 rescue 0
      self[ event ] = simulation.marking.map do |n|
        n.round SAMPLING_DECIMAL_PLACES rescue n
      end
    end

    # Recording value at a given point.
    # 
    def at event
      fetch event
    end
  end # class Recording
end # YPetri::Simulation
