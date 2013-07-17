# encoding: utf-8

# A mixin for timed simulations.
# 
class YPetri::Simulation
  module Timed
    require_relative 'timed/recording'
    require_relative 'timed/core'

    DEFAULT_SETTINGS = -> do { step: 0.1, sampling: 5, time: 0..60 } end

    def self.included receiver
      receiver.Recording.class_exec { prepend Recording }
    end

    # True for timed simulations.
    # 
    def timed?
      true
    end

    attr_reader :time,
                :time_unit,
                :initial_time,
                :target_time

    alias starting_time initial_time
    alias ending_time target_time

    attr_accessor :step

    delegate :flux_vector_TS,
             :gradient_TS,
             :gradient_Ts,
             :gradient,
             :flux_vector,
             to: :core

    delegate :sampling,
             to: :recording

    # Initialization subroutine.
    #
    def init **nn
      if nn.has? :time, syn!: :time_range then # time range given
        time_range = nn[:time]
        @initial_time = time_range.begin
        @target_time = time_range.end
        @time_unit = target_time / target_time.to_f
      else
        anything = nn[:step] || nn[:sampling]
        msg = "The simulation is timed, but the constructor lacks any of the " +
          "time-related arguments: :time, :step, or :sampling!"
        fail ArgumentError, msg unless anything
        @time_unit = anything / anything.to_f
        @initial_time = time_unit * 0
        @target_time = time_unit * Float::INFINITY
      end

      @step = nn[:step] || time_unit

      @Recording = Class.new Recording
      @Core = Class.new Core
      tap do |sim|
        [ Recording(),
          Core()
        ].each { |ç| ç.class_exec { define_method :simulation do sim end } }
      end

      reset_time!

      @recording = Recording().new

      recording.sampling = nn[:sampling] || step
    end

    # Reads the time range (initial_time..target_time) of the simulation.
    #
    def time_range
      initial_time..target_time
    end

    # Reads the settings pertaining to the Timed aspoect of the simulation:
    # (:step, :sampling and :time).
    #
    def settings
      super.update step: step,
      sampling: sampling,
      time: time_range
    end

    # Near alias for #run!, checks against infinite run.
    #
    def run( to=target_time, final_step: :exact )
      fail "Target time equals infinity!" if target_time == Float::INFINITY
      run!( to, final_step: final_step )
    end

    # Near alias for #run_until, uses @target_time as :until_time by default.
    #
    def run!( to=target_time, final_step: :exact )
      run_until( to, final_step: final_step )
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
    def run_until( target_time, final_step: :exact )
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

    # Produces the inspect string for this timed simulation.
    #
    def inspect
      "#<Simulation: Time: #{time}, #{pn.size} places, #{tn.size} " +
        "transitions, object id: #{object_id}>"
    end

    # Produces a string brief
    def to_s                         # :nodoc:
      "Simulation[time: #{time}, P: #{pn.size}, T: #{tn.size}]"
    end

    # Increments the simulation's time.
    #
    def increment_time! Δt=step
      @time += Δt
      recording.note_state_change
    end

    # Resets the timed simulation.
    #
    def reset!
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
    def zero_∇( places: nil )
      return zero_∇( places: places() ) if places.nil?
      places.each { |id|
        pl = place( id )
        if pl.free? then
          pl.initial_marking * 0 / time_unit
        else
          pl.clamp * 0 / time_unit
        end
      }.to_column_vector
    end

    # Resets the time to initial time, or to the argument (if provided).
    #
    def reset_time! time=nil
      @time = time.nil? ? initial_time : time
    end
  end # module Timed
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
