# encoding: utf-8

# Agent instance methods related to simulation (initial marking collections,
# clamp collections, initial marking collections, management of simulations...)
# 
module YPetri::Agent::SimulationRelated
  require_relative 'hash_key_pointer'
  require_relative 'selection'

  # Simulation selection class.
  # 
  SimulationSelection = YPetri::Agent::Selection.parametrize agent: self

  # Simulation settings collection selection class.
  # 
  SscSelection = YPetri::Agent::Selection.parametrize agent: self

  # Clamp collection selection class.
  # 
  CcSelection = YPetri::Agent::Selection.parametrize agent: self

  # Initial marking collection selection class.
  # 
  ImcSelection = YPetri::Agent::Selection.parametrize agent: self

  class SimulationPoint < YPetri::Agent::HashKeyPointer
    # Reset to the first simulation, or nil if that is absent.
    # 
    def reset
      @key = @hash.empty? ? nil : set( @hash.first[0] )
    end

    # A simulation is identified either by its name (if named), or by its
    # parameters and settings (:net, :cc, :imc, :ssc).
    # 
    def set **nn
      key = identify **nn
      @key = if key.nil? then key
             elsif @hash.has_key? key then key
             else raise "No simulation identified by #{key}!" end
    end

    # Helper method specifying how a simulation is identified by arguments.
    # 
    def identify( name: nil, net: nil, cc: nil, imc: nil, ssc: nil, **nn )
      name || { net: net, cc: cc, imc: imc, ssc: ssc }.merge( nn )
    end
  end

  # Pointer to a collection of simulation settings.
  # 
  SscPoint = YPetri::Agent::HashKeyPointer.parametrize agent: self

  # Pointer to a clamp collection.
  # 
  CcPoint = YPetri::Agent::HashKeyPointer.parametrize agent: self

  # Pointer to a collection of initial markings.
  # 
  ImcPoint = YPetri::Agent::HashKeyPointer.parametrize agent: self

  attr_reader :simulation_point,
              :ssc_point,
              :cc_point,
              :imc_point,
              :simulation_selection,
              :ssc_selection,
              :cc_selection,
              :imc_selection

  def initialize
    # set up this manipulator's pointers
    @simulation_point = SimulationPoint.new( hash: simulations,
                                             hash_value_is: "simulation" )
    @ssc_point = SscPoint.new( hash: simulation_settings_collections,
                                     hash_value_is: "simulation settings collection",
                                     default_key: :Base )
    @cc_point = CcPoint.new( hash: clamp_collections,
                             hash_value_is: "clamp collection",
                             default_key: :Base )
    @imc_point = ImcPoint.new( hash: initial_marking_collections,
                               hash_value_is: "initial marking collection",
                               default_key: :Base )
    # set up this manipulator's selections
    @simulation_selection = SimulationSelection.new
    @ssc_selection = SscSelection.new
    @cc_selection = CcSelection.new
    @imc_selection = ImcSelection.new
    # do anything else prescribed
    super
  end

  # Simulation-related methods delegated to the workspace.
  delegate :simulations,
           :clamp_collections,
           :initial_marking_collections,
           :simulation_settings_collections,
           :clamp_collection_names, :ncc,
           :initial_marking_collection_names, :nimc,
           :simulation_settings_collection_names, :nssc,
           :set_clamp_collection, :ncc,
           :set_initial_marking_collection, :nimc,
           :set_simulation_settings_collection, :set_ssc,
           :new_simulation,
           :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
           to: :world

  # Returns the simulation identified by the argument, or one at simulation
  # point, if no argument given. The simulation is identified in the same way
  # as for #simulation_point_to method.
  # 
  def simulation *args
    return simulation_point.get if args.empty?
    SimulationPoint.new( hash: simulations, hash_value_is: "simulation" ).get
  end

  # Returns identified clamp collection, or (if no argument given) one
  # corresponding to cc_point.
  # 
  def clamp_collection id=nil
    if id.nil? then cc_point.get else clamp_collections[ id ] end
  end
  alias cc clamp_collection

  # Returns identified initial marking collection, or (if no argument given)
  # one corresponding to imc_point.
  # 
  def initial_marking_collection id=nil
    if id.nil? then imc_point.get else
      initial_marking_collections[ id ]
    end
  end
  alias imc initial_marking_collection

  # Returns identified simulation settings collection, or (if no argument given)
  # one corresponding to ssc_point.
  # 
  def simulation_settings_collection id=nil
    if id.nil? then ssc_point.get else
      simulation_settings_collections[ id ]
    end
  end
  alias ssc simulation_settings_collection

  # FIXME: This is going to be tested

  def clamp clamp_hash
    clamp_hash.each_pair do |place, clamp|
      clamp_collection.merge! workspace.place( place ) => clamp
    end
  end

  # Returns or modifies current initial marking(s) as indicated by the argument
  # field:
  # * No arguments: returns current imc
  # * Exactly one ordered argument: it is assumed to identify a place whose
  #   im in the current imc will be returned.
  # * A hash: Assumed to be { place_id => im }, current imc is updated with it.
  # * One ordered argument, and a hash: The imc identified by the ordered
  #   ordered arg is updated with the hash.
  # * 2 ordered arguments: First is assumed to identify an imc, second place
  #   whose im acc. to that imc to return.
  # 
  def initial_marking *args;
    oo = args.extract_options!
    case args.size
    when 0 then
      if oo.empty? then            # no ordered arguments were given,
        initial_marking_collection # current imc will be returned
      else # hash was supplied, assumed of pairs { place_id => marking },
        initial_marking_collection # it will be merged to imc
          .update( oo.with_keys do |key| place( key ) end )
      end
    when 1 then                    # exactly one ordered argument was given,
      if oo.empty? then            # without any named arguments, it is
        place = place( args[0] )   # assumed that it identifies a place,
        initial_marking_collection[ place ] # return its init. marking in imc
      else # One ordered argument (imc), and one hash (update values) given.
        im_coll = initial_marking_collection( args[0] )
        im_coll.update( oo.with_keys do |key| place( key ) end )
      end
    when 2 then # 2 ordered arguments (imc, place whose marking to return)
      im_coll = initial_marking_collection( args[0] )
      place = place( args[1] )
      im_coll[ place ]
    else raise ArgumentError, "Too many ordered parameters" end
  end
  alias im initial_marking

  # Changes the time step of the current ssc (ssc = simulation settings
  # collection).
  # 
  def set_step Δt
    ssc.update step_size: Δt
  end
  alias set_step_size set_step

  # Sets the time frame of the current ssc (sim. settings collection).
  # 
  def set_time time_range
    ssc.update time: time_range.aT_kind_of( Range )
  end

  # Sets the time frame of the current ssc to run from zero to the time supplied
  # as the argument.
  # 
  def set_target_time time
    set_time time * 0 .. time
  end
    
  # Changes the sampling period of the current ssc (ssc = simulation
  # settings collection).
  # 
  def set_sampling Δt
    ssc.update sampling_period: Δt
  end

  # Changes the simulation method of the current ssc (ssc = simulation
  # settings collection).
  # 
  def set_simulation_method m
    ssc.update method: m
  end

  # Create a new timed simulation and make it available in the simulations
  # table.
  # 
  def new_simulation *args, &block
    instance = workspace.new_simulation( *args, &block )
    # Set the point to it
    simulation_point.set( simulations.rassoc( instance )[0] )
    return instance
  end

  # Create a new timed simulation and run it.
  # 
  def run!
    new_simulation.run!
  end

  # Write the recorded samples in a file (csv).
  # 
  def print_recording( filename=nil )
    if filename.nil? then
      puts simulation.recording.to_csv
    else
      File.open( filename, "w" ) do |f|
        f << simulation.recording.to_csv
      end
    end
  end

  # Plot the recorded samples.
  # 
  def plot **features
    # --> state feature ids
    # --> gradient feature ids
    # --> delta feature ids
    # --> flux feature ids
    # --> firing feature ids

    # take these features together

    # construct the labels and the time series for each

    # plot them

    return nil unless sim = @workspace.simulations.values[-1] # sim@point
    # Decide abnout the features
    features = sim.places.dup.map { |p|
      collection.include?( p ) ? p : nil
    }
    # Get recording
    rec = sim.recording
    # Select a time series for each feature.
    time_series = features.map.with_index do |feature, i|
      feature and rec.map { |key, val| [ key, val[i] ] }.transpose
    end
    # Time axis
    ᴛ = sim.target_time
    # Gnuplot call
    gnuplot( ᴛ, features.compact.map( &:name ), time_series.compact,
             title: "Selected features plot", ylabel: "Marking" )
  end

  # Plot the recorded samples (system state history).
  # 
  def plot_state( place_ids=nil, except: [] )
    sim = simulation or return nil
    feat = sim.pp( place_ids || sim.pp ) - sim.pp( Array except )
    gnuplot sim.record.marking( feat ), time: sim.target_time,
            title: "State plot", ylabel: "Marking"
  end
  alias plot_marking plot_state

  # Plot the recorded flux (computed flux history at the sampling points).
  # 
  def plot_flux( transition_ids=nil, **options )
    sim = @workspace.simulations.values[-1] or return nil # sim@point
    tt = sim.TS_transitions( transition_ids ).sources
    excluded = sim.transitions( Array options[:except] ).sources
    tt -= excluded
    flux = sim.recording.modify do |time, record|
      [ time,
        sim.at( time: time, marking: record ).TS_transitions( tt ).flux_vector ]
    end
    # Select a time series for each feature.
    time_series = tt.map.with_index do |tr, i|
      tr and flux.map { |time, flux| [ time, flux[i] ] }.transpose
    end
    # Time axis
    time = sim.target_time
    # Gnuplot call
    gnuplot( time, tt.compact.names, time_series.compact,
             title: "Flux plot", ylabel: "Flux [µMⁿ.s⁻¹]" )
  end

  private

  # Gnuplots a recording. Target time or time range can be supplied as :time
  # named argument.
  # 
  def gnuplot( dataset, time: nil, **nn )
    event_vector = dataset.events
    data_vectors = dataset.values.transpose
    x_range = if time.is_a? Range then
                "[#{time.begin}:#{time.end}]"
              else
                "[-0:#{SY::Time.magnitude( time ).amount rescue time}]"
              end
    labels = recording.features.labels

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.xrange x_range
        plot.title nn[:title] || "Simulation plot"
        plot.ylabel nn[:ylabel] || "Values"
        plot.xlabel nn[:xlabel] || "Time [s]"

        labels.zip( data_vectors ).each { |label, data_vector|
          plot.data << Gnuplot::DataSet.new( [event_vector, data_vector] ) { |ds|
            ds.with = "linespoints"
            ds.title = lbl
          }
        }
      end
    end
  end
end # module YPetri::Agent::SimulationRelated