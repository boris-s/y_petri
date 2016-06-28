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

  attr_accessor :step, :target_time

  # Explicit alias for +#step=+ method. Deprecated, use +#step=+ instead.
  # 
  def set_step n
    step=( n )
  end
  alias set_step_size set_step

  # Explicit alias for +#target_time=+ method. Deprecated, use +#target_time=+
  # instead.
  # 
  def set_time target_time
    target_time=( target_time )
  end
  alias set_target_time set_time

  delegate :sampling,
           :sampling=, to: :recorder

  # Sets sampling of the simulation's data recorder.
  # 
  def set_sampling sampling
    recorder.sampling = sampling
  end 

  # Changing the simulation method on the fly not supported.
  # 
  def set_simulation_method
    fail NotImplementedError,
         "Changing simulation method on the fly not supported!"
  end

  delegate :flux_vector_TS,
           :gradient_TS,
           :gradient_Ts,
           :gradient,
           :flux_vector,
           to: :core

  # Expects a single array of TS transitions or transition ids and returns an
  # array of their fluxes under current marking.
  #
  def Fluxes( array )
    tt = TS_transitions()
    TS_Transitions( array )
      .map { |t| flux_vector.column_to_a.fetch tt.index( t ) }
  end

  # Expects an arbitrary number of arguments identifying TS transitions, and
  # retuns an array of their fluxes. Returns fluxes of all the TS transitions
  # if no argument is given.
  #
  def fluxes( *transitions )
    return Fluxes TS_transitions() if transitions.empty?
    Fluxes( transitions )
  end
  alias flux fluxes

  # Fluxes of the indicated TS transitions. Expects a single array argument,
  # and returns a hash with transition names as keys.
  # 
  def T_fluxes( array )
    TS_Transitions( array ).names( true ) >> Fluxes( array )
  end
  alias t_Fluxes T_fluxes

  # Fluxes of the indicated TS transitions. Expects an arbitrary number of
  # TS transitions or their ids, returns a hash with transition names as keys.
  # 
  def t_fluxes( *transitions )
    return T_fluxes TS_transitions() if transitions.empty?
    T_fluxes( transitions )
  end
  alias t_flux t_fluxes

  # Pretty prints flux of the indicated TS transitions as a hash with transition
  # names as keys. Takes optional list of transition ids (first ordered arg.),
  # and optional 2 named arguments (+:gap+ and +:precision+), as in
  # +#pretty_print_numeric_values+.
  # 
  def pflux( *transitions, gap: 0, precision: 4 )
    t_flux( *transitions )
      .pretty_print_numeric_values( gap: gap, precision: precision )
  end
  alias pfluxes pflux

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
  # stop_before:     last step has normal size, simulation stops before or just
  #             on the target time
  # stop_after:      last step has normal size, simulation stops after or just
  #             on the target time_step
  # exact:           simulation stops exactly on the prescribed time, last step
  #                  is shortened if necessary
  #
  def run_upto( target_time, final_step: :exact )
    case final_step
    when :stop_before then
      step! while time + step <= target_time
    when :exact then
      step! while time + step < target_time
      step!( target_time - time )
      @time = target_time
    when :stop_after then
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
    recorder.alert!
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
  def dup time: time(), **named_args
    super( **named_args ).tap { |instance| instance.reset_time! time }
  end

  # Alias for +#dup+ for timed simulations.
  # 
  def at *args
    dup *args
  end

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

  protected

  # Resets the time to initial time, or to the argument (if provided).
  #
  def reset_time! time=nil
    @time = time.nil? ? initial_time : time
  end

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
        @time_unit = case initial_time
                     when Float then 1.0
                     when Integer then 1
                     else
                       initial_time.class.one
                     end
      else
        # TODO: When using simulation after some time, I found this behavior
        # surprising. I wanted to call simulation time: 100, expecting it
        # to run until 100 (in the range 0..100). Instead, I see that it wants
        # to run from 100 to infinity. While I understand how important it
        # is to have a simple way to set the time of a newly constructed
        # simulation to some value (for the purposes such as cloning of
        # simulation, interpolation of simulations etc. -- actually, there
        # is no really stateful net in YPetri at the moment, so Simulation
        # class behaves somewhat as a stateful net...), not just me, but
        # other users might expect :time argument to set final time with
        # initial time being 0. I'm not gonna change it quite yet.
        #
        # The way to refactor it would be to first introduce "initial_time"
        # parameter and make "time" parameter raise an error, and refactor
        # the code until the tests pass. Then, to reintroduce "time"
        # parameter with the new, more intuitive meaning. Interactive
        # users can always modify time later (simulation.time = something).
        # 
        @initial_time = settings[:time]
        @time_unit = case initial_time
                     when Float then 1.0
                     when Integer then 1
                     else
                       initial_time.class.one
                     end
        @target_time = time_unit * Float::INFINITY
      end
    else
      anything = settings[:step] || settings[:sampling]
      msg = "The simulation is timed, but the constructor lacks any of the " +
        "time-related arguments: :time, :step, or :sampling!"
      fail ArgumentError, msg unless anything
      @time_unit = case anything
                   when Float then 1.0
                   when Integer then 1
                   else
                     anything.class.one
                   end
      @initial_time, @target_time = time_unit * 0, time_unit * Float::INFINITY
    end
    # Set up a parametrized subclas of the sampler for timed simulation.
    param_class( { Recorder: Recorder }, with: { simulation: self } )
    reset_time!
    @step = settings[:step] || time_unit
    @default_sampling = settings[:sampling] || step
    if method == :runge_kutta then
      # This is a bit irregular for now, but since the core has to behave
      # differently (that is, more like a real simulation core), at least
      # for the more advanced runge_kutta method, a core under a different
      # instance variable will be constructed.
      @rk_core = if @guarded then
                   YPetri::Core::Timed.new( simulation: self, method: method, guarded: true )
                 else
                   YPetri::Core::Timed.new( simulation: self, method: method, guarded: false )
                 end
      singleton_class.class_exec do
        attr_reader :rk_core
        delegate :simulation_method,
                 :firing_vector_tS,
                 to: :rk_core
        
        # This method steps the simulation forward by the prescribed step. Simulation uses the core to perform the #step! method.
        # 
        def step! Δt=step()
          # Pseudocode would be like this:
          
          # 1. set_state_and_time_of_core_to_the_current_simulation's_state_and_time
          
          # 2. explicitly tell the core the code by which to alert the sampler when necessary
          # ie. when the state vector of the core progresses sufficiently for it to be
          # interesting to the sampler

          # 3. explicitly tell the core the code by which to update the simulation's state,
          # and when should it be updated.
          #
          # (Note: This can be done in several ways. For example, one possibility is to
          # update the simulation only after the core is finished computing. Another
          # possibility is to have some other criterion to update the simulation more
          # often in the course of the core's work. Since this is some sort of sampling
          # job again, there is an option of actually delegating it to the sampler,
          # which would thus get closer to its role of the interface.)
          #
          # (Note 2: It is actually more clear what the role of the core should be rather
          # than what the simulation's role should be. The core should receive the initial
          # instructions, a relatively simple method of what to do, and it should be
          # specialized in doing its job fast. Secondly, it should receive the method for
          # alerting the superiors: simulation and/or sampler. Thirdly, it should be told
          # when to stop.)

          # This should set the state of the rk_core to the marking vector of free
          # places (#marking_vector method).
          rk_core.marking_of_free_places.reset!( marking_vector )
          sim, rec = self, recorder
          rk_core.set_user_alert_closure do |mv_free| # marking vect. of free places
            # TODO: This can be done differently. For example, the simulation can hand
            # the core the function which, when handed a hash, will update the marking
            # vector with the hash. This is actually quite similar, but there is some
            # ugliness in it...
            sim.m_vector.reset! mv_free.to_hash
            sim.increment_time! Δt
            Kernel.print '.'
            rec.alert!
          end

          rk_core.step! Δt

          # TODO: In the above lines, setting rec = recorder and then calling
          # rec!.alert in the block is a bit weird. It would be nicer to use
          # recorder.alert!, but maybe
          # wise Ruby closure mechanism does not allow it...
        end # def step!
      end # singleton_class.class_exec
    else # the method is not :runge_kutta
      @core = if @guarded then
                YPetri::Core::Timed.new( simulation: self,
                                         method: method, guarded: true )
              else
                YPetri::Core::Timed.new( simulation: self,
                                         method: method, guarded: false )
              end
      # TODO: But why am I doing it like this? Did I want to
      # emphasize the standalone nature of Core class? Maybe... And
      # maybe I did it so that the runge-kutta method with its
      # @rk_core instance variable instead of @core does not have
      # @core and #core.  In this manner, I'm forcing myself to
      # rethink Simulation class.
      singleton_class.class_exec do
        attr_reader :core
        delegate :simulation_method, # this looks quite redundant with simulation.rb
                 :step!,
                 :firing_vector_tS,
                 to: :core
      end # singleton_class.class_exec
    end 
    @recorder = if features_to_record then
                  # we'll have to figure out features
                  ff = case features_to_record
                       when Array then
                         net.State.Features
                           .infer_from_nodes( features_to_record )
                       when Hash then
                         net.State.features( features_to_record )
                       end
                  Recorder().new( sampling: settings[:sampling], features: ff )
                else
                  Recorder().new( sampling: settings[:sampling] )
                end
  end # def init
end # module YPetri::Simulation::Timed
