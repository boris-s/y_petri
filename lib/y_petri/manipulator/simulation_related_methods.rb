# -*- coding: utf-8 -*-
# Manipulator instance methods related to simulation (initial marking
# collections, clamp collections, initial marking collections, management
# of simulations...)
# 
module YPetri::Manipulator::SimulationRelatedMethods
  require_relative 'hash_key_pointer'
  require_relative 'selection'

  # Simulation selection class.
  # 
  SimulationSelection = Class.new YPetri::Manipulator::Selection

  # Simulation settings collection selection class.
  # 
  SscSelection = Class.new YPetri::Manipulator::Selection

  # Clamp collection selection class.
  # 
  CcSelection = Class.new YPetri::Manipulator::Selection

  # Initial marking collection selection class.
  # 
  ImcSelection = Class.new YPetri::Manipulator::Selection

  class SimulationPoint < YPetri::Manipulator::HashKeyPointer
    # Reset to the first simulation, or nil if that is absent.
    # 
    def reset; @key = @hash.empty? ? nil : set( @hash.first[0] ) end

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
  SscPoint = Class.new YPetri::Manipulator::HashKeyPointer

  # Pointer to a clamp collection.
  # 
  CcPoint = Class.new YPetri::Manipulator::HashKeyPointer

  # Pointer to a collection of initial markings.
  # 
  ImcPoint = Class.new YPetri::Manipulator::HashKeyPointer

  attr_reader :simulation_point, :ssc_point, :cc_point, :imc_point,
              :simulation_selection, :ssc_selection,
              :cc_selection, :imc_selection

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
           :clamp_collection_names, :cc_names,
           :initial_marking_collection_names, :imc_names,
           :simulation_settings_collection_names, :ssc_names,
           :set_clamp_collection, :set_cc,
           :set_initial_marking_collection, :set_imc,
           :set_simulation_settings_collection, :set_ssc,
           :new_timed_simulation,
           :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
           to: :workspace

  # Returns the simulation identified by the argument, or one at simulation
  # point, if no argument given. The simulation is identified in the same way
  # as for #simulation_point_to method.
  # 
  def simulation *args
    return simulation_point.get if args.empty?
    SimulationPoint.new( hash: simulations, hash_value_is: "simulation" ).get
  end

  # # TEMPORARY KLUGE - FIXME
  # # 
  # def simulation; @workspace.simulations.values[-1] end

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
  #   im in teh current imc will be returned.
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
  def new_timed_simulation *args, &block
    instance = workspace.new_timed_simulation( *args, &block )
    # Set the point to it
    simulation_point.set( simulations.rassoc( instance )[0] )
    return instance
  end

  # Create a new timed simulation and run it.
  # 
  def run!
    new_timed_simulation.run!
  end

  # Write the recorded samples in a file (csv).
  # 
  def print_recording( filename = nil )
    if filename.nil? then
      puts simulation.recording_csv_string
    else
      File.open( filename, "w" ) do |f|
        f << simulation.recording_csv_string
      end
    end
  end

  # Plot the recorded samples.
  # 
  def plot *args
    oo = args.extract_options!
    case args.size
    when 0 then plot_recording oo
    when 1 then
      plot_what = args[0]
      case plot_what
      when :state then plot_recording oo
      when :flux then plot_flux oo
      when :all then plot_all oo
      else plot_selected *args end
    else raise "Too many ordered arguments!" end
  end

  # Plot the selected features.
  # 
  def plot_selected *args
    oo = args.extract_options!
    collection = Array args[0]
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
  def plot_state( *args )
    oo = args.extract_options!
    excluded = Array oo[:except]
    return nil unless sim = @workspace.simulations.values[-1] # sim@point
    # Decide about the features to plot.
    features = excluded.each_with_object sim.places.dup do |x, α|
      i = α.index x
      α[i] = nil if i
    end
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
             title: "State plot", ylabel: "Marking" )
  end

  # Plot the recorded flux (computed flux history at the sampling points).
  # 
  def plot_flux( *args )
    oo = args.extract_options!
    excluded = Array oo[:except]
    return nil unless sim = @workspace.simulations.values[-1] # sim@point
    # Decide about the features to plot.
    all = sim.SR_transitions
    features = excluded.each_with_object all.dup do |x, α|
      i = α.index x
      if i then α[i] = nil end
    end
    # Get recording.
    rec = sim.recording
    # Get flux recording.
    flux = rec.modify { |ᴛ, ᴍ| [ ᴛ, sim.at( t: ᴛ, m: ᴍ ).flux_for( *all ) ] }
    # Select a time series for each feature.
    time_series = features.map.with_index do |feature, i|
      feature and flux.map { |ᴛ, flux| [ ᴛ, flux[i] ] }.transpose
    end
    # Time axis
    ᴛ = sim.target_time
    # Gnuplot call
    gnuplot( ᴛ, features.compact.map( &:name ), time_series.compact,
             title: "Flux plot", ylabel: "Flux [µMⁿ.s⁻¹]" )
  end

  private

  # Gnuplots things.
  # 
  def gnuplot( time, labels, time_series, *args )
    labels = labels.dup
    time_series = time_series.dup
    oo = args.extract_options!

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.xrange "[-0:#{SY::Time.magnitude( time ).amount rescue time}]"
        plot.title oo[:title] || "Simulation plot"
        plot.ylabel oo[:ylabel] || "Values"
        plot.xlabel oo[:xlabel] || "Time [s]"

        labels.zip( time_series ).each { |label, series|
          plot.data << Gnuplot::DataSet.new( series ) do |data_series|
            data_series.with = "linespoints"
            data_series.title = label
          end
        }
      end
    end
  end
end # module YPetri::Manipulator
