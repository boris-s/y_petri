# encoding: utf-8

# A machine that receives alerts during simulation and records a recording
# according to its implementation. Alerts are received via +#alert!+ method.
# The recording being recorded is stored in +@recording+ instance variable.
# This can be reset by +#reset!+ method, which also accepts arguments to
# change the recorder settings and/or insert another recording.
#
class YPetri::Simulation::Recorder
  ★ YPetri::Simulation::Dependency

  SAMPLING_DECIMAL_PLACES = 5

  attr_reader :features

  def recording
    @recording.tap { |dataset|
      dataset.instance_variable_set :@settings, simulation.settings( true )
    }
  end

  delegate :simulation,
           to: "self.class"

  delegate :reconstruct,
           :reduce,
           to: :recording

  # Initializes the recorder. Takes 2 arguments: +:features+ expecting the
  # feature set to record during simulation, and +:recording+, expecting the
  # initial state of the recording.
  # 
  def initialize features: net.State.Features.Marking( free_pp ),
                 recording: nil,
                 **nn
    @features = net.State.Features( features )
    recording ? reset!( recording: recording ) : reset!
  end

  # Construct a new recording based on the Recording() class.
  # 
  def new_recording
    @features.DataSet.new
  end

  # Assigns to +@recording+ a new +DataSet+ instance. If no arguments are
  # supplied to this method, the new recording will stay empty. A recording
  # can be optionally supplied via +:recording+ named argument.
  # 
  def reset! features: nil, recording: nil, **named_args
    @features = net.State.Features( features ) if features
    @recording = new_recording
    @recording.update Hash[ recording ] if recording
    return self
  end

  # Hook to be called by simulators whenever there is a state change. The
  # decision to sample is then the business of the recorder.
  # 
  def alert!
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
