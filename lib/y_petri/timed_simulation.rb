#encoding: utf-8

module YPetri

  # A descendant class of YPetri::Simulation that introduces timekeeping.
  # 
  class TimedSimulation < Simulation
    SAMPLING_TIME_DECIMAL_PLACES = SAMPLING_DECIMAL_PLACES

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

    # Reads sampling rate.
    # 
    def sampling_rate; 1 / sampling_period end

    # Reads time range of the simulation.
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
        
    # Exposing time.
    # 
    attr_reader :time

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
    def initialize *aa; oo = aa.extract_options!
      puts "starting TimedSimulation init" if DEBUG
      # LATER: possibility of transition clamps
      # @simulation_method = :implicit_euler # hard-wired so far
      # simulation step size
      oo.must_have :step_size, syn!: :step
      @step_size = oo.delete :step_size
      oo.must_have :sampling_period, syn!: :sampling
      @sampling_period = oo.delete :sampling_period
      oo.may_have :target_time
      @target_time = oo.delete :target_time
      @initial_time = oo.delete( :initial_time ) || @target_time * 0 rescue 0
      puts "about to call super" if DEBUG
      super *aa, oo
      puts "successfuly set up a TimedSimulation" if DEBUG
    end

    # At the moment, near alias for #run_to_arget_time!
    # 
    def run! target=target_time; run_until_target_time! target; return self end

    # Scalar field gradient for free places.
    # 
    def gradient_for_free_places
      puts "about to compute gradient for free places" if DEBUG
      fv = flux_vector_for_SR_transitions
      puts "flux vector for SR transitions is \n#{Hash[tt.zip( fv.map &:to_s )]}" if DEBUG
      puts "List of free places is #{free_pp}" if YPetri::DEBUG
      sm = S_for_SR_transitions()
      puts "stoichiometry matrix for SR transitions is \n#{sm}" if DEBUG
      ∂ = sm * fv
      puts "about to add the contribution of sR transitions" if DEBUG
      rslt = ∂ + ∂_for_sR_transitions
      puts "returning #{rslt}" if DEBUG
      rslt
    end
    alias :∂_free :gradient_for_free_places
    alias :gradient :gradient_for_free_places
    alias :∂ :gradient_for_free_places

    # Scalar field gradient for all places.
    # 
    def gradient_for_all_places; free_places_to_all_places_matrix * ∂_free end
    alias :∂_all :gradient_for_all_places
    alias :gradient! :gradient_for_all_places
    alias :∂! :gradient_for_all_places

    # Δ state for free places that would happen by a single Euler step Δt.
    # 
    def delta_state_Euler_for_free_places( Δt=step_size )
      puts "∂_free is #{∂_free}" if YPetri::DEBUG
      ∂_free * Δt + Δ_for_TSr_transitions( Δt ) + Δ_for_Tsr_transitions( Δt )
      # Here, ∂_free already comprises transitions with rate, and
      # the remaining two terms represent timed rateless transitions.
      # As for the timeless transitions, it is imaginable that they would
      # fire eg. once per 1 time unit, but this is already different method,
      # not Euler.
    end
    alias :delta_state_euler_for_free_places :delta_state_Euler_for_free_places
    alias :Δ_Euler_free :delta_state_Euler_for_free_places
    alias :Δ_euler_free :delta_state_Euler_for_free_places
    alias :Δ_Euler :delta_state_Euler_for_free_places
    alias :Δ_euler :delta_state_Euler_for_free_places

    # Δ state for all places that would happen by a single Euler step Δt.
    # 
    def delta_state_Euler_for_all_places( Δt=step_size )
      free_places_to_all_places_matrix * Δ_Euler_free( Δt )
    end
    alias :delta_state_euler_for_all_places :delta_state_Euler_for_all_places
    alias :Δ_Euler_all :delta_state_Euler_for_all_places
    alias :Δ_euler_all :delta_state_Euler_for_all_places

    # Steps once, using implicit Euler on whole system (ie. no mysode). Custom
    # step length will be used, if given as an argument to the function.
    # 
    def Euler_step!( Δt=@step_size ) # implicit Euler method
      update_marking! Δ_Euler_free( Δt )
      update_time! Δt
      note_state_change!
    end
    alias :euler_step! :Euler_step!
    alias :E! :Euler_step!
    alias :e! :Euler_step!

    # At the moment, near alias of #euler_step!
    # 
    def step! Δt=step_size
      # LATER: Use mysode on "interior"
      Euler_step!( Δt )
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
    def run_until_target_time!( target, stepping_opt=:exact )
      case stepping_opt
      when :just_before then # step until on or just before the target
        step! while @time + @step_size <= target
      when :exact then # simulate to exact time
        step! while @time + @step_size < target
        step!( target - @time )      # make a short last step as required
        @time = target               # to get exactly on the prescribed time
      when :just_after then # step until on or after target
        step! while @time < target
      else raise "Invalid stepping option: #{stepping_opt}" end
    end

    def inspect                      # :nodoc:
      "#<YPetri::TimedSimulation: #{pp.size} places, #{tt.size} " +
        "transitions, time: #{time}, object id: #{object_id} >"
    end

    def to_s                         # :nodoc:
      "TimedSimulation[ #{pp.size} pp, #{tt.size} tt, T: #{time} ]"
    end

    private

    def reset!
      @time = initial_time
      @next_sampling_time = @time
      super # otherwise same as for timeless cases
    end

    # Records a sample, now.
    def sample!; super time.round( SAMPLING_TIME_DECIMAL_PLACES ) end

    # Hook to allow Simulation to react to its state changes.
    def note_state_change!
      return nil unless @time.round( 9 ) >= @next_sampling_time.round( 9 )
      sample!
      @next_sampling_time += @sampling_period
    end

    def update_time! Δt=step_size; @time += Δt end
  end # class TimedSimulation
end # module YPetri

# Speaking about the simulation method, in general, each element of a net
# can, in general, be simulated using a different method. From the pragmaticp
# point of view, however, many good simulation methods have been developed
# for the ordinary differential equations of the form:
#
# (1) State(t) = Integral ( f(state, t), dt ), where f(state, t) is known
# function. Now, it's better to know its Jacobian, too, but not necessary -
# can be computed)
#
# #FIXME: Look up proper notation in Advanced Engineering Mathematics
#
# Now, many of these methods depend on Jacobian, but that cannot be computed
# for all of the places. Therefore, the places, whose marking defines the
# system state, are divided into two categories: "A" (accelerated) places,
# for which as a group Jacobian can be found, and "E" places, where "E" can
# stand either for "External" or "Euler".
#
# While Simulation class is not a chemical factor in any sense, the
# definition of "causal orientation" of border transition can be applied to
# it. Then, it can be said that among border transitions between "A" and "E"
# places, only the transitions causally oriented towards "A" places are
# allowed for compliance with the equation (1).
#
# Clamping is a problem of its own.
