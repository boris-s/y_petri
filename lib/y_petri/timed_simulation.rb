# -*- coding: utf-8 -*-
# A descendant class of YPetri::Simulation that introduces timekeeping.
# 
class YPetri::TimedSimulation < YPetri::Simulation
  SAMPLING_TIME_DECIMAL_PLACES = SAMPLING_DECIMAL_PLACES
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
    { step_size: step_size,
      sampling_period: sampling_period,
      time_range: time_range }
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

  # In addition to the arguments required by the regular simulation
  # constructor, timed simulation constructor also expects :step_size
  # (alias :step), :sampling_period (alias :sampling), and :target_time
  # named arguments.
  # 
  def initialize( **named_args )
    named_args.must_have :step_size, syn!: :step
    named_args.must_have :sampling_period, syn!: :sampling
    named_args.may_have :target_time
    named_args.may_have :initial_time
    @step_size = named_args.delete :step_size
    @sampling_period = named_args.delete :sampling_period
    @target_time = named_args.delete :target_time
    @initial_time = named_args.delete( :initial_time ) ||
      @target_time.nil? ? nil : @sampling_period * 0 # @target_time.class.zero
    super( **named_args )
    @zero_gradient = @zero_ᴍ.map { |e| step_size.to_f / step_size * e }
  end
  # LATER: transition clamps

  # Allows to explore the system at different state / time. Creates a double,
  # which is set to the required state / time. In addition to the parent class,
  # this version alseo sets time.
  # 
  def at *args
    oo = args.extract_options!
    duplicate = super *args, oo
    t = oo.may_have( :t, syn!: :ᴛ ) and duplicate.send :set_time, t
    return duplicate
  end

  # At the moment, near alias for #run_to_arget_time!
  # 
  def run! until_time=target_time
    run_until_target_time! until_time
    return self
  end

  # Scalar field gradient for free places.
  # 
  def gradient_for_free_places
    g_sR = gradient_for_sR
    if g_sR then
      S_for_SR() * flux_vector_for_SR + g_sR
    else
      S_for_SR() * flux_vector_for_SR
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
    g_free = gradient_for_free_places * Δt
    g_free + Δ_for_TSr( Δt ) + Δ_for_Tsr( Δt )
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
    update_marking! Δ_Euler_for_free_places( Δt )
    update_time! Δt
  end
  alias euler_step! Euler_step!

  # Fires timeless transitions once. Time and timed transitions are not
  # affected.
  # 
  def timeless_transitions_all_fire!
    update_marking! Δ_if_tS_fire_once + Δ_if_tsa_fire_once
    assignment_transitions_all_fire!
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
      Euler_step!
      timeless_transitions_all_fire!
      note_state_change!
    when :Euler_with_timeless_transitions_firing_after_each_time_tick,
      :quasi_Euler then
      raise                          # FIXME: quasi_Euler doesn't work yet
      Euler_step!
      # if time tick has elapsed, call #timeless_transitions_all_fire!
      note_state_change!
    else
      raise "Unrecognized simulation method: #@method !!!"
    end
    return self
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
  def run_until_target_time!( t=target_time, stepping_opt=:exact )
    case stepping_opt
    when :just_before then    # step until on or just before the target
      step! while @time + @step_size <= t
    when :exact then          # simulate to exact time
      step! while @time + @step_size < t
      step!( t - @time )      # make a short last step as required
      @time = t               # to get exactly on the prescribed time
    when :just_after then     # step until on or after target
      step! while @time < t
    else raise "Invalid stepping option: #{stepping_opt}" end
  end
  alias run_until! run_until_target_time!

  # Produces the inspect string for this timed simulation.
  # 
  def inspect
    "#<YPetri::TimedSimulation: #{pp.size} places, #{tt.size} " +
      "transitions, time: #{time}, object id: #{object_id} >"
  end

  # Produces a string brief
  def to_s                         # :nodoc:
    "TimedSimulation[ #{pp.size} pp, #{tt.size} tt, T: #{time} ]"
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

  # Duplicate creation. TODO: Like with Simulation#duplicate, this should
  # be thought over, whether this should actually be #dup or #clone method.
  # 
  def duplicate
    instance = super
    instance.send :set_time, time
    return instance
  end
end # class YPetri::TimedSimulation

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
