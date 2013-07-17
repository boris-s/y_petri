# Timed simulation -- recording.
# 
module YPetri::Simulation::Timed
  class Recording < YPetri::Simulation::Recording
    TIME_PRECISION = 5

    delegate :time, to: :simulation
    attr_reader :next_sampling_time
    attr_accessor :sampling

    # Like +YPetri::Simulation::Recording#reset+, allowing for additional named
    # argument +:next_time+ that sets the next sampling time.
    # 
    def reset! **nn
      super
      next_time = nn[:next_time] || simulation.time
      @next_sampling_time = next_time
    end

    # Hook to allow Simulation to react to its state changes.
    # 
    def note_state_change
      t = simulation.time.round( 9 )
      t2 = next_sampling_time.round( 9 )
      if t >= t2 then
        sample! # !sample it the sampling time has passed
        @next_sampling_time += sampling
      else nil end
    end

    # Records the current state as { time => system_state }.
    # 
    def sample!
      sampling_event = time.round( TIME_PRECISION )
      super sampling_event
    end

    # Recreates the simulation at a given time point. Linear interpolation is
    # used for the time points not recorded.
    # 
    def at time, **nn
      simulation.dup marking: linear_interpolation( time ), **nn
    end

    # Provide linear interpolation of the recording for a given time.
    # 
    def linear_interpolation( time )
      begin
        fetch( time )
      rescue KeyError
        f_time, floor = floor( time )
        c_time, ceiling = ceiling( time )
        floor + ( ceiling - floor ) / ( c_time - f_time ) * ( time - f_time )
      end
    end

    # ...
    # 
    def features slice: labels, **nn
      ss = []
      if nn.has? :gradient then
        ss += gradient_series **nn.delete( :gradient ).update( slice: slice )
      end
      if nn.has? :flux then
        ss += flux_series nn.delete( :flux ), slice: slice
      end
      if nn.has? :delta then
        ss += delta_series **nn.delete( :delta ).update( slice: slice )
      end
      ss = ss.transpose
      super( slice: slice, **nn ).with_values!.with_index do |record, i|
        record.concat ss[i]
      end
    end

    # ...
    # 
    def gradient_series places: places, transitions: transitions, slice: labels
      
    end

    def gradient_features ids, slice: labels
      features gradient: ids, slice: slice
    end

    # ...
    # 
    def flux_series ids=nil, slice: labels
      
    end

    def flux_features ids, slice: labels
      features flux: ids, slice: slice
    end

    # ...
    # 
    def delta_series places: places, transitions: transitions, slice: labels
      
    end

    def delta_features ids, slice: labels
      features delta: ids, slice: slice
    end
  end
end
