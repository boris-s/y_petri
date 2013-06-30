# -*- coding: utf-8 -*-

# A mixin for timed simulations.
# 
module YPetri::Simulation::Timed
  SAMPLING_TIME_DECIMAL_PLACES = 5
  SIMULATION_METHODS =
    [
      [ :Euler ],
      [ :Euler_with_timeless_transitions_firing_after_each_time_tick, :quasi_Euler ],
      [ :Euler_with_timeless_transitions_firing_after_each_step, :pseudo_Euler ]
    ]
  DEFAULT_SIMULATION_METHOD = :Euler

  # ==== Exposing time-related global simulation settings

  # Simulation parameter: :initial_time.
  # 
  attr_reader :initial_time
  
  # Simulation parameter: :step_size
  # 
  attr_accessor :step_size
  
  # Simulation parameter: :sampling_period
  # 
  attr_accessor :sampling_period
  
  # Simulation parameter: :target_time
  # 
  attr_accessor :target_time
  
  # Reads the sampling rate.
  # 
  def sampling_rate; 1 / sampling_period end
  
  # Reads the time range (initial_time..target_time) of the simulation.
  # 
  def time_range; initial_time..target_time end
  
  # Reads simulation settings
  # (:step_size, :sampling_period and :time_range).
  # 
  def settings
    { step: step_size,
      sampling: sampling_period,
      time: time_range }
  end
  alias simulation_settings settings

  # Exposing time.
  # 
  attr_reader :time
  alias ᴛ time

  # def stop; end # LATER
  # def continue; end # LATER

  # # Makes one Gillespie step
  # def gillespie_step
  #   t, dt = gillespie_select( @net.transitions )
  #   @marking_vector += t.project( @marking_vector, @step_size )
  #   @time += dt
  #   note_state_change
  # end

  # # Return projection of Δᴍ by mysode-ing the interior.
  # def project_mysode_interior( Δt )
  #   # So far, no interior
  #   # the internals of this method were already heavily obsolete
  #   # they can be seen in previous versions, if needed
  #   # so now, I just take use of the Δ_Euler_free
  #   Δ_Euler_free
  # end

  # Allows to explore the system at different state / time. Creates a double,
  # which is set to the required state / time. In addition to the parent class,
  # this version alseo sets time.
  # 
  def at( time: ᴛ, **oo )
    super( **oo ).tap { |duplicate| duplicate.send :set_time, time }
  end

  # Near alias for #run!, checks against infinite run.
  # 
  def run( until_time=target_time, final_step: :exact )
    fail "Target time equals infinity!" if target_time = Float::INFINITY
    run! until_time, final_step: final_step
  end

  # Near alias for #run_until, uses @target_time as :until_time by default.
  # 
  def run!( until_time=target_time, final_step: :exact )
    run_until until_time, final_step: final_step
  end

  # Runs the simulation until the target time, using step! method. The second
  # optional parameter tunes the behavior towards the end of the run, with
  # alternatives :just_before, :just_after and :exact (default).
  #
  # just_before:     all steps have normal size, simulation stops
  #                  before or just on the target time
  # just_after:      all steps have normal size, simulation stops
  #                  after or just on the target time_step
  # exact:           simulation stops exactly on the prescribed time,
  #                  to make this possible last step is shortened if necessary
  #
  def run_until( target_time, final_step: :exact )
    case final_step
    when :before then              # step until on or just before the target
      step! while @time + @step_size <= target_time
    when :exact then               # simulate to exact time
      step! while @time + @step_size < target_time
      step!( target_time - @time ) # make a short last step as required
      @time = target_time          # to get exactly on the prescribed time
    when :after then               # step until on or after target
      step! while @time < target_time
    else
      fail ArgumentError, "Unrecognized :final_step option: #{final_step}"
    end
  end

  # Scalar field gradient for free places.
  # 
  def gradient_for_free_places
    g_sR = gradient_for_sR
    if g_sR then
      S_SR() * flux_vector_for_SR + g_sR
    else
      S_SR() * flux_vector_for_SR
    end
  end

  # Gradient for free places as a hash { place_name: ∂ / ∂ᴛ }.
  #
  def ∂
    free_places :gradient_for_free_places
  end

  # Scalar field gradient for all places.
  # 
  def gradient_for_all_places
    F2A() * gradient_for_free_places
  end
  alias gradient gradient_for_all_places

  # Δ state of free places that would happen by a single Euler step Δt.
  # 
  def Δ_Euler_for_free_places( Δt=step_size )
    # Here, ∂ represents all R transitions, to which TSr and Tsr are added:
    delta_free = gradient_for_free_places * Δt
    delta_free + Δ_TSr( Δt ) + Δ_Tsr( Δt )
  end
  alias Δ_euler_for_free_places Δ_Euler_for_free_places
  alias ΔE Δ_Euler_for_free_places

  # Δ state of all places that would happen by a single Euler step Δt.
  # 
  def Δ_Euler_for_all_places( Δt=step_size )
    F2A() * ΔE( Δt )
  end
  alias Δ_euler_for_all_places Δ_Euler_for_all_places
  alias Δ_Euler Δ_Euler_for_all_places

  # Makes one Euler step with T transitions. Timeless transitions are not
  # affected.
  # 
  def Euler_step!( Δt=@step_size ) # implicit Euler method
    delta = Δ_Euler_for_free_places( Δt )
    if guarded? then
      guard_Δ! delta
      update_marking! delta
    else
      update_marking! delta
    end
    update_time! Δt
  end
  alias euler_step! Euler_step!

  # Fires timeless transitions once. Time and timed transitions are not
  # affected.
  # 
  def timeless_transitions_all_fire!
    try "to update marking" do
      update_marking!( note( "Δ state if tS transitions fire once",
                             is: Δ_if_tS_fire_once ) +
                       note( "Δ state if tsa transitions fire once",
                             is: Δ_if_tsa_fire_once ) )
    end
    try "to fire the assignment transitions" do
      assignment_transitions_all_fire!
    end
  end
  alias t_all_fire! timeless_transitions_all_fire!

  # At the moment, near alias of #euler_step!
  # 
  def step! Δt=step_size
    case @method
    when :Euler then
      Euler_step! Δt
      note_state_change!
    when :Euler_with_timeless_transitions_firing_after_each_step,
      :pseudo_Euler then
      Euler_step! Δt
      timeless_transitions_all_fire!
      note_state_change!
    when :Euler_with_timeless_transitions_firing_after_each_time_tick,
      :quasi_Euler then
      raise                          # FIXME: quasi_Euler doesn't work yet
      Euler_step! Δt
      # if time tick has elapsed, call #timeless_transitions_all_fire!
      note_state_change!
    else
      raise "Unrecognized simulation method: #@method !!!"
    end
    return self
  end

  # Produces the inspect string for this timed simulation.
  # 
  def inspect
    "#<Simulation: Time: #{time}, #{pp.size} places, #{tt.size} " +
      "transitions, object id: #{object_id}>"
  end

  # Produces a string brief
  def to_s                         # :nodoc:
    "Simulation[T: #{time}, pp: #{pp.size}, tt: #{tt.size}]"
  end

  private

  def reset!
    @time = initial_time || 0
    @next_sampling_time = @time
    super # otherwise same as for timeless cases
  end

  # Records a sample, now.
  def sample!
    print '.'
    super time.round( SAMPLING_TIME_DECIMAL_PLACES )
  end

  # Hook to allow Simulation to react to its state changes.
  def note_state_change!
    return nil unless @time.round( 9 ) >= @next_sampling_time.round( 9 )
    sample!
    @next_sampling_time += @sampling_period
  end

  def update_time! Δt=step_size
    @time += Δt
  end

  def set_time t
    @time = t
  end

  # Duplicate creation.
  # 
  def dup
    instance = super
    instance.send :set_time, time
    return instance
  end
end # module YPetri::Simulation::Timed

# In general, it is not required that all net elements are simulated with the
# same method. Practically, ODE systems have many good simulation methods
# available.
#
# (1) ᴍ(t) = ϝ f(ᴍ, t).dt, where f(ᴍ, t) is a known function.
#
# Many of these methods depend on the Jacobian, but that may not be available
# for some places. Therefore, the places, whose marking defines the system
# state, are divided into two categories: "A" (accelerated), for which as
# common Jacobian can be found, and "E" places, where "E" can stand either for
# "External" or "Euler".
#
# If we apply the definition of "causal orientation" on A and E places, then it
# can be said, that only the transitions causally oriented towards "A" places
# are allowed for compliance with the equation (1).
