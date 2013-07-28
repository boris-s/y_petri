class YPetri::Simulation
  # A machine that receives alerts during simulation and records a recording
  # according to its implementation. Alerts are received via +#alert+ method.
  # The recording bein recorded is stored in @recording instance variable.
  # This can be reset by +#reset!+ method, which also accepts arguments to
  # change the recorder settings and/or insert another recording.
  #
  class Recorder
    include Dependency

    SAMPLING_DECIMAL_PLACES = 5

    attr_reader :features, :recording
    delegate :simulation, to: :class
    delegate :reconstruct, :reduce, to: :recording

    # Initializes the recorder. Takes 2 arguments: +:features+ expecting the
    # feature set to record during simulation, and +:recording+, expecting the
    # initial state of the recording.
    # 
    def initialize features: net.State.Features.marking, # marking and nothing else
                   recording: features.new_dataset,
                   **nn
      @features = net.State.features( features )
      reset! recording: recording
    end

    # Assigns to @recording a new Dataset instance. Without arguments, the new
    # recording is empty. With +:recording+ named argument supplied, the new
    # recording is filled with the prescribed contents.
    # 
    def reset! **nn
      @recording = features.new_dataset
      @recording.update Hash[ nn[:recording] ] if nn[:recording]
    end

    # Hook to be called by simulators whenever there is a state change. The
    # decision to sample is then the business of the recorder.
    # 
    def alert
      sample! # vanilla recorder samples at every occasion
    end

    private

    # Records the current state as a pair { sampling_event => system_state }.
    # 
    def sample! event
      record = simulation.get_features( features )
      recording[ event ] = record.dump( precision: SAMPLING_DECIMAL_PLACES )
    end
  end # class Recorder
end # YPetri::Simulation
