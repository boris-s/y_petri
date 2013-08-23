# encoding: utf-8

# A machine that receives alerts during simulation and records a recording
# according to its implementation. Alerts are received via +#alert+ method.
# The recording bein recorded is stored in @recording instance variable.
# This can be reset by +#reset!+ method, which also accepts arguments to
# change the recorder settings and/or insert another recording.
#
class YPetri::Simulation::Recorder
  ★ YPetri::Simulation::Dependency

  SAMPLING_DECIMAL_PLACES = 5

  attr_reader :features

  def recording
    @recording.tap { |ds|
      ds.instance_variable_set :@settings, simulation.settings( true )
    }
  end

  delegate :simulation, to: "self.class"
  delegate :reconstruct, :reduce, to: :recording

  # Initializes the recorder. Takes 2 arguments: +:features+ expecting the
  # feature set to record during simulation, and +:recording+, expecting the
  # initial state of the recording.
  # 
  def initialize features: net.State.marking( free_pp ),
                 recording: nil,
                 **nn
    @features = net.State.features( features )
    if recording then reset! recording: recording else reset! end
  end

  # Construct a new recording based on the parametrized class Recording().
  # 
  def new_recording
    features.new_dataset
  end

  # Assigns to @recording a new Dataset instance. Without arguments, the new
  # recording is empty. With +:recording+ named argument supplied, the new
  # recording is filled with the prescribed contents.
  # 
  def reset! **nn
    @features = net.State.features( nn[:features] || @features )
    @recording = new_recording
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
end # class YPetri::Simulation::Recorder
