# encoding: utf-8

# A mixin for timed simulations, used by an +#extend+ call during init.
# 
module YPetri::Simulation::Timed
  require_relative 'timed/recorder'

  DEFAULT_SETTINGS = -> do { step: 0.1, sampling: 5, time: 0..60 } end

  # True for timed simulations.
  # 
  def timed?
    true
  end

  attr_reader :time,
              :time_unit,
              :initial_time,
              :target_time,
              :step,
              :default_sampling

  alias starting_time initial_time
  alias ending_time target_time

  delegate :flux_vector_TS,
           :gradient_TS,
           :gradient_Ts,
           :gradient,
           :flux_vector,
           to: :core

  delegate :sampling, to: :recorder

  # Returns the flux of the indicated TS transitions (all TS transitions,
  # if no argument is given).
  #
  def flux ids_of_TS_transitions=nil
    tt = TS_transitions()
    return flux tt if ids_of_TS_transitions.nil?
    TS_transitions( ids_of_TS_transitions ).map { |t|
      flux_vector.column_to_a.fetch tt.index( t )
    }
  end

  # Flux of the indicated TS transitions (as hash with transition names as keys).
  # 
  def t_flux ids=nil
    TS_transitions( ids ).names( true ) >> flux( ids )
  end

  # Pretty prints flux of the indicated TS transitions as hash with transition
  # names as keys. Takes optional list of transition ids (first ordered arg.),
  # and optional 2 named arguments (+:gap+ and +:precision), as in
  # +#pretty_print_numeric_values+.
  # 
  def pflux ids=nil, gap: 0, precision: 3
    t_flux( ids ).pretty_print_numeric_values( gap: gap, precision: precision )
  end

  # Reads the time range (initial_time .. target_time) of the simulation.
  #
  def time_range
    initial_time .. target_time
  end

  # Returns the settings pertaining to the Timed aspect of the simulation,
  # that is, +:step+, +:sampling+ and +:time+.
  #
  def settings all=false
    super.update( step: step,
                  sampling: sampling,
                  time: time_range )
  end

  # Same as +#run!+, but guards against run upto infinity.
  # 
  def run( upto: target_time, final_step: :exact )
    fail "Upto time equals infinity!" if upto == Float::INFINITY
    run!( upto: upto, final_step: final_step )
  end

  # Near alias for +#run_upto+. Accepts +:upto+ named argument, using
  # @target_time attribute as a default. The second optional argument,
  # +:final_step+, has the same options as in +#run_upto+ method.
  # 
  def run!( upto: target_time, final_step: :exact )
    run_upto( upto, final_step: final_step )
  end

  # Runs the simulation until the target time. Named argument :final_step has
  # options :just_before, :just_after and :exact, and tunes the simulation
  # behavior towards the end of the run.
  #
  # just_before:     last step has normal size, simulation stops before or just
  #                  on the target time
  # just_after:      last step has normal size, simulation stops after or just
  #                  on the target time_step
  # exact:           simulation stops exactly on the prescribed time, last step
  #                  is shortened if necessary
  #
  def run_upto( target_time, final_step: :exact )
    case final_step
    when :before then
      step! while time + step <= target_time
    when :exact then
      step! while time + step < target_time
      step!( target_time - time )
      @time = target_time
    when :after then
      step! while time < target_time
    else
      fail ArgumentError, "Unrecognized :final_step option: #{final_step}"
    end
  end

  # String representation of this timed simulation.
  # 
  def to_s
    "#<Simulation: time: %s, pp: %s, tt: %s, oid: %s>" %
      [ time, pp.size, tt.size, object_id ]
  end

  # Increments the simulation's time and alerts the recorder.
  #
  def increment_time! Δt=step
    @time += Δt
    recorder.alert
  end

  # Resets the timed simulation.
  #
  def reset! **nn
    @time = initial_time || time_unit * 0
    super
  end

  # Customized dup method that allows to modify the attributes of
  # the duplicate upon creation.
  #
  def dup time: time, **nn
    super( **nn ).tap { |i| i.reset_time! time }
  end
  alias at dup

  # Returns the zero gradient. Optionally, places can be specified, for which
  # the zero vector is returned.
  #
  def zero_gradient places: nil
    return zero_gradient places: places() if places.nil?
    places.map { |id|
      p = place( id )
      ( p.free? ? p.initial_marking : p.clamp ) * 0 / time_unit
    }.to_column_vector
  end
  alias zero_∇ zero_gradient

  private

  # Initialization subroutine for timed simulations. Expects named arguments
  # +:time+ (alias +:time_range+), meaning the simulation time range (a Range
  # of initial_time..target_time), +:step+, meaning time step of the
  # simulation, and +:sampling+, meaning sampling period of the simulation.
  #
  # Initializes the time-related attributes @initial_time, @target_time,
  # @time_unit and @time (via +#reset_time!+ call). Also sets up the
  # parametrized subclasses +@Core+ and +@Recorder+, and initializes the
  # +@recorder+ attribute.
  #
  def init **settings
    method = settings[:method] # the simulation method
    features_to_record = settings[:record]
    if settings.has? :time, syn!: :time_range then # time range given
      case settings[:time]
      when Range then
        time_range = settings[:time]
        @initial_time, @target_time = time_range.begin, time_range.end
        @time_unit = initial_time.class.one
      else
        @initial_time = settings[:time]
        @time_unit = initial_time.class.one
        @target_time = time_unit * Float::INFINITY
      end
    else
      anything = settings[:step] || settings[:sampling]
      msg = "The simulation is timed, but the constructor lacks any of the " +
        "time-related arguments: :time, :step, or :sampling!"
      fail ArgumentError, msg unless anything
      @time_unit = anything.class.one
      @initial_time, @target_time = time_unit * 0, time_unit * Float::INFINITY
    end
    init_core_and_recorder_subclasses
    reset_time!
    @step = settings[:step] || time_unit
    @default_sampling = settings[:sampling] || step
    @core = Core().new( method: method, guarded: guarded )
    @recorder = if features_to_record then
                  # we'll have to figure out features
                  ff = case features_to_record
                       when Array then
                         net.State.Features
                           .infer_from_elements( features_to_record )
                       when Hash then
                         net.State.features( features_to_record )
                       end
                  Recorder().new( sampling: settings[:sampling], features: ff )
                else
                  Recorder().new( sampling: settings[:sampling] )
                end
  end

  # Sets up subclasses of +Core+ (the simulator) and +Recorder+ (the sampler)
  # for timed simulations.
  # 
  def init_core_and_recorder_subclasses
    param_class( { Core: YPetri::Core::Timed, Recorder: Recorder },
                 with: { simulation: self } )
  end

  # Resets the time to initial time, or to the argument (if provided).
  #
  def reset_time! time=nil
    @time = time.nil? ? initial_time : time
  end
end # module YPetri::Simulation::Timed
