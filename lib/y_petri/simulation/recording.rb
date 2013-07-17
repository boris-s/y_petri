# Basic elements of a simulation, a mixin intended for YPetri::Simulation.
#
class YPetri::Simulation
  class Recording < Hash
    include DependencyInjection

    class << self
      alias __new__ new
      
      def new *args
        __new__ *args do |hsh, missing|
          hsh[ Float( missing ) ] unless missing.is_a? Float
        end
      end
    end

    SAMPLING_DECIMAL_PLACES = 5

    alias labels keys

    # Without an argument, resets the recording to empty. With a named argument
    # +:recording+, resets the recording to a new specified recording.
    # 
    def reset! **nn
      clear
      new_recording = nn[:recording]
      update Hash[ new_recording ] unless new_recording.nil?
    end

    # Hook to be called by the simulation methods whenever the state changes.
    # Recording mechanics then takes care of the sampling.
    # 
    def note_state_change
      sample! # default for vanilla Simulation: sample! at every occasion
    end

    # Records the current state as a pair { sampling_event => system state }.
    # 
    def sample! event_label
      self[ event_label ] = simulation.marking.map do |n|
        n.round SAMPLING_DECIMAL_PLACES rescue n
      end
    end

    # Recreates the simulation at a given event label.
    # 
    def at label, **nn
      simulation.dup marking: fetch( label ), **nn
    end

    # Outputs the current recording in CSV format.
    # 
    def to_csv
      map { |lbl, rec| [ lbl, *rec ].join ',' }.join "\n"
    end

    # Expects a hash of features (:marking (alias :state) of places, :firing
    # of tS transitions, :delta of places and/or transitions) and returns the
    # corresponding mapping of the recording.
    # 
    def features slice: labels, **nn
      ss = []
      if nn.has? :marking, syn!: :state then
        ss += marking_series places: nn[:marking], slice: slice
      end
      if nn.has? :firing then
        ss += firing_series transitions: nn[:firing], slice: slice 
      end
      if nn.has? :delta then
        ss += delta_series **nn[:delta].update( slice: slice )
      end
      build ss, slice: slice
    end

    # Takes an array of place identifiers, and returns an array of marking series
    # for those places. Optional :slice argument (Range or Array) specifies which
    # slice of recording to return (whole recording by default).
    # 
    def marking_series places: free_places, slice: labels
      ii = simulation.places.indices_of places( places )
      slice( slice ).map { |_, record| record.values_at *ii }.transpose
    end
    alias state_series marking_series

    # Returns the history for the selected marking features.
    # 
    def marking places: free_places, slice: labels
      features marking: places, slice: slice
    end

    # Takes an array of tS transition identifiers, and returns an array of firing
    # series for those tS transitions. Optional :slice argument (Range or Array)
    # specifies which slice of recording to return (whole recording by default).
    # 
    def firing_series transitions: simulation.tS_transitions, slice: labels
      ii = simulation.transitions.indices_of transitions( transitions )
      slice( slice ).map { |lbl, _|
        at( lbl ).transitions( transitions ).tS.firing
      }.transpose
    end

    # Returns the history for the selected firing features.
    # 
    def firing ids=nil, slice: labels
      features firing: simulation.tS_transitions, slice: slice if ids.nil?
      features firing: ids, slice: slice
    end

    # Takes an array of place identifiers, an array of transition identifiers,
    # and returns the corresponding series of the transitions' delta
    # contributions to those places in one step.  Optional :slice argument
    # (Range or Array) specifies, which slice of the recording to return (whole
    # recording by default).
    # 
    def delta_series places: places, transitions: transitions, slice: labels
      ii = simulation.places.indices_of places( places )
      slice( slice ).map { |lbl, _|
        at( lbl ).transitions( transitions ).t.delta
          .column( 0 ).to_a.values_at *ii
      }.transpose
    end

    # Returns the history for the selected delta features.
    # 
    def delta ids, slice: labels
      features delta: ids, slice: slice
    end

    # TODO: Customized #slice method returning a Recording instance?

    private

    # Expects an array of series, where each series is itself an array of values,
    # and returns a reconstructed recording hash for the series. Optional :slice
    # argument (Range or Array) specifies, which slice of recording is being
    # built (whole recording by default).
    # 
    def build series, slice: labels
      kk = slice( slice ).keys
      kk >> series.each_with_object( kk.map { [] } ) do |series, memo|
        memo.each_with_index { |ary, i| ary << series[i] }
      end
    end
  end # class Recording
end # YPetri::Simulation
