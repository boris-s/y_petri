#encoding: utf-8

# Public command interface of YPetri.
# 
class YPetri::Manipulator

  # Current workspace.
  # 
  def workspace;
    # puts "Manipulator is #{self}, obj. id #{object_id}."
    @workspace
  end

  def initialize
    new_workspace_instance = YPetri::Workspace.new
    @workspace = new_workspace_instance
    net_point_reset
    net_selection_clear
    simulation_point_reset
    simulation_selection_clear
    ssc_point_reset
    ssc_selection_clear
    cc_point_reset
    cc_selection_clear
    imc_point_reset
    imc_selection_clear
  end

  delegate :place, :transition,
           :p, :t,
           :places, :transitions, :nets,
           :simulations,
           :pp, :tt, :nn,
           :clamp_collections,
           :initial_marking_collections,
           :simulation_settings_collections,
           :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
           to: :workspace

  # Place constructor: Creates a new place in the current workspace.
  # 
  def Place *args, &block
    workspace.Place.new *args, &block
  end

  # Transiton constructor: Creates a new transition in the current workspace.
  # 
  def Transition *args, &block
    workspace.Transition.new *args, &block
  end

  # Net constructor: Creates a new Net instance in the current workspace.
  # 
  def Net *args, &block
    workspace.Net.new *args, &block
  end

  # ==== Net point

  # Sets net point to workspace.Net::Top
  # 
  def net_point_reset
    net_point_to( workspace.Net::Top )
  end

  # Sets net point to the one identified in the argument (Net instance or
  # its name).
  # 
  def net_point_to which_net
    @net_point = workspace.net which_net
  end
  alias :net→ :net_point_to

  # Returns the net identified by the argument, or the net at the point, if
  # none given.
  # 
  def net which=nil
    which.nil? ? @net_point : workspace.net( which )
  end

  # Returns the name of the net identified by the argument, or the net at the
  # point (if no argument is given).
  # 
  def n which=nil
    net( which ).name
  end

  # ==== Simulation point

  # Sets simulation point to the first key of the workspace's collection of
  # simulations (or nil if there are no simulations yet).
  # 
  def simulation_point_reset
    @simulation_point =
      workspace.simulations.empty? ? nil :
      simulation_point_to( workspace.simulations.first[0] )
  end

  # Sets simulation point to the simulation identified by the argument.
  # A simulation can be identified either by its name (if named), or by
  # its parameters and settings (simulated net, clamp collection, initial
  # marking collection, and simulation settings collection).
  #
  # If a single ordered (non-hash) argument is supplied, it is assumed to be
  # a simulation name. If a hash is supplied, it is expected that it will
  # contain four pairs with keys :net, :cc, :imc, :ssc, identifying the
  # simulation by its parameters and settings. Alternatively, use of hash
  # can be forgone - if exactly 4 ordered arguments are supplied, it is
  # assumed that they specified the parameter settings in the order set forth
  # earlier.
  # 
  def simulation_point_to *args
    key = normalize_simulation_identifier *args
    @simulation_point = if key.nil? then nil
                        elsif workspace.simulations.has_key? key then key
                        else raise "No such simulation" end
  end
  alias :sim→ :simulation_point_to

  # Returns the simulation identified by the argument, or one indicated by the
  # simulation point (if no argument was given). The simulation is identified
  # by the arguments in the same way as for #simulation_point_to method.
  # 
  def simulation *args
    workspace.simulation( normalize_simulation_identifier *args )
  end

  # TEMPORARY KLUGE - FIXME
  # 
  def simulation; @workspace.simulations.values[-1] end

  # Returns the index (position) of the simulation point.
  # 
  def simulation_point_position
    # FIXME: Change @simulations from being a has of { key => simulation } pairs
    # to be the hash of { simulation => names } pairs, in which simulations are
    # looked up either by rassoc or by sniffing their parameters and settings.
    @simulation_point
  end

  # ==== cc point (cc = clamp collection)

  # Clamp collections are stored in workplace in a hash. The cc point
  # points to its keys.

  # Resets cc point to :base.
  # 
  def cc_point_reset
    @cc_point = :Base
  end

  # Sets the cc point to the specified cc.
  # 
  def cc_point_to arg
    if workspace.clamp_collections.has_key? arg
      @cc_point = arg
    else
      raise "No clamp collection #{arg} in this workspace"
    end
  end
  alias :cc→ :cc_point_to

    # Returns clamp collection corresp. to cc point (if no argument), or to
    # the argument (if this was given).
    # 
    def clamp_collection collection_name=nil
      cɴ = collection_name.nil? ? @cc_point : collection_name
      workspace.clamp_collections[ cɴ ] or
        raise AE, "No clamp collection #{cɴ} in this workspace."
    end
    alias :cc :clamp_collection

    # Returns the cc point position (cc hash key).
    # 
    def cc_point_position; @cc_point end

    # ==== imc point ( imc = initial marking collection )

    # Initial marking collections are stored in a workplace in a hash.
    # The imc point points to its keys.

    # Resets imc point to :base.
    # 
    def imc_point_reset; @imc_point = :Base end

    # Sets the imc point to the specified imc.
    # 
    def imc_point_to arg
      if workspace.initial_marking_collections.has_key? arg
        @imc_point = arg
      else
        raise "No initial marking collection #{arg} in this workspace."
      end
    end
    alias :imc→ :imc_point_to

    # Returns initial marking collection corresp. to imc point (if no
    # argument), or to the argument (if this was given).
    # 
    def initial_marking_collection collection_name=nil
      cɴ = collection_name.nil? ? @imc_point : collection_name
      workspace.initial_marking_collections[ cɴ ] or
        raise AE, "No initial marking collection #{cɴ} in this workspace."
    end
    alias :imc :initial_marking_collection

    # Returns the ssc point position (ssc hash key).
    # 
    def imc_point_position; @imc_point end

    # ==== ssc point (ssc = simulation settings collection)

    # Simulation settings collections are stored in workplace in a hash.
    # The ssc point of manipulator points to its keys.

    # Resets ssc point to :base.
    # 
    def ssc_point_reset; @ssc_point = :Base end

    # Sets the ssc point to the specified ssc.
    # 
    def ssc_point_to arg
      if workspace.simulation_settings_collections.has_key? arg
        @ssc_point = arg
      else raise "No such simulation settings collection: #{arg}" end
    end
    alias :ssc→ :ssc_point_to

  # Returns the ssc identified by the argument, or that at ssc point (if no
  # argument is given).
  # 
  def simulation_settings_collection collection_name=nil
    cɴ = collection_name.nil? ? @ssc_point : collection_name
    # puts "Target workspace is #{workspace}, obj. id #{workspace.object_id}"
    workspace.simulation_settings_collections[ cɴ ] or
      raise AE, "No simulations settings collection #{cɴ} in this workspace."
  end
  alias :ssc :simulation_settings_collection

  # Returns the ssc point position (ssc hash key).
  # 
  def ssc_point_position; @ssc_point end


  # ==== Selection mechanism for net, simulation, cc, imc and ssc
  # TODO

  # Net selection.
  # 
  attr_reader :net_selection

  # Simulation selection.
  # 
  attr_reader :simulation_selection

  # Simulation settings collection selection.
  # 
  attr_reader :ssc_selection

  # Clamp collection selection.
  # 
  attr_reader :cc_selection

  # Initial marking collection selection.
  # 
  attr_reader :imc_selection

  # ==== Net selection

  def net_selection_clear
    @net_selection ||= []
    @net_selection.clear
  end

  def net_select! *aa; net_selection_clear; net_select *aa end

  def net_select *aa
    case aa.size
    when 0 then ( @net_selection << net ).uniq!
    when 1 then ( @net_selection << aa[0] ).uniq!
    else aa.each { |a| net_select a } end
  end

  def net_unselect *aa
    if aa.empty? then @net_selection.delete net else
      aa.each { |arg| @net_selection.delete net( arg ) }
    end
  end

  # --- simulation selection ---------------------------------------------

  def simulation_selection_clear
    @simulation_selection ||= []
    @simulation_selection.clear
  end

  def simulation_select! *aa
    simulation_selection_clear
    simulation_select *aa
  end

  def simulation_select *aa
    # FIXME
  end

  def simulation_unselect *aa
    # FIXME
  end

  # --- cc selection -----------------------------------------------------

  def cc_selection_clear; @cc_selection ||= []; @cc_selection.clear end

  def cc_select! *aa; cc_selection_clear; cc_select *aa end

  def cc_select
    # FIXME
  end

  def cc_unselect *aa
    # FIXME
  end

  # --- imc selection ----------------------------------------------------

  def imc_selection_clear; @imc_selection ||= []; @imc_selection.clear end

  def imc_select! *aa; imc_selection_clear; imc_select *aa end

  def imc_select
    # FIXME
  end

  def imc_unselect *aa
    # FIXME
  end

  # --- ssc selection ----------------------------------------------------

  def ssc_selection_clear; @ssc_selection ||= []; @ssc_selection.clear end

  def ssc_select! *aa; ssc_selection_clear; ssc_select *aa end

  def ssc_select
    # FIXME
  end

  def ssc_unselect *aa
    # FIXME
  end

  # --- rest of the world ------------------------------------------------
  # FIXME: This is going to be tested

  def clamp clamp_hash
    clamp_hash.each_pair { |pl, cl|
      clamp_collection.merge! workspace.place( pl ) => cl
    }
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
    else raise AE, "Too many ordered parameters" end
  end
  alias :im :initial_marking

  # Changes the time step of the current ssc (ssc = simulation settings
  # collection).
  # 
  def set_step Δt
    ssc.update step_size: Δt
  end
  alias :set_step_size :set_step

  # Changes the simulation time of the current ssc (ssc = simulation
  # settings collection).
  # 
  def set_time t
    ssc.update target_time: t
  end
  alias :set_target_time :set_time

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
    simulation_point_to( simulations.rassoc( instance )[0] )
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
      when :recording then plot_recording oo
      when :flux then plot_flux oo
      when :all then plot_all oo
      else raise "Unknown y_petri plot type: #{plot_what} !!!" end
    else raise "Too many ordered arguments!" end
  end

  # Plot the recorded samples (system state history).
  # 
  def plot_recording( *args )
    oo = args.extract_options!
    excluded = Array oo[:except]
    return nil unless sim = @workspace.simulations.values[-1] # sim@point
    # Decide about the features to plot.
    features = excluded.each_with_object sim.places.dup do |x, α|
      i = α.index x
      if i then α[i] = nil end
    end
    # Get recording
    rec = sim.recording
    # Select a time series for each feature.
    time_series = features.map.with_index do |feature, i|
      feature and rec.map { |key, val| [ key, val[i] ] }.transpose
    end
    # Time axis
    ᴛ = simulation.target_time
    # Gnuplot call
    gnuplot( ᴛ, features.compact.map( &:name ), time_series.compact )
  end

  # Plot the recorded flux (computed flux history at the sampling points).
  # 
  def plot_flux( *args )
    oo = args.extract_options!
    excluded = Array oo[:except]
    return nil unless sim = @workspace.simulations.values[-1] # sim@point
    # Decide about the features to plot.
    features = excluded.each_with_object sim.SR.dup do |x, α|
      i = α.index x
      if i then α[i] = nil end
    end.compact
    puts 'before danger'
    # Get flux recording.
    flux_rec = Hash[ sim.recording.map { |ᴛ, ᴍ|
                       [ ᴛ, sim.at( t: ᴛ, m: ᴍ ).flux_for( *features ) ]
                     } ]
    puts 'so far so good'
    # Select a time series for each feature.
    time_series = features.map.with_index do |feature, i|
      feature and flux_rec.map { |ᴛ, flux| [ ᴛ, flux[i] ] }.transpose
    end
    puts 'about to plot'
    # Time axis
    ᴛ = simulation.target_time
    # Gnuplot call
    gnuplot( ᴛ, features.map( &:name ), time_series )
  end

  private

  # Gnuplots things.
  # 
  def gnuplot( time, labels, time_series )
    labels = labels.dup
    time_series = time_series.dup

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.xrange "[-0:#{SY::Time.magnitude( time ).amount rescue time}]"
        plot.title "Recording Plot"
        plot.ylabel "marking"
        plot.xlabel "time [s]"

        labels.zip( time_series ).each { |label, series|
          plot.data << Gnuplot::DataSet.new( series ) do |data_series|
            data_series.with = "linespoints"
            data_series.title = label
          end
        }
      end
    end
  end

  # Helper method allowing more flexible access to the simulations stored in
  # the current workspace. A single, non-hash ordered argument is considered
  # a simulation name. A hash argument is assumed to be have keys :net, :cc,
  # :imc, :ssc, by which to identify a simulation. Hash keys can be forgone if
  # 4 ordered arguments are supplied: These are then considered to represent
  # the values of a hash with the above keys, and are converted to such hash.
  # Summarizing this, there is a single return value, with which a simulation
  # can be identified - this return value is either a hash of simulation
  # parameters and settings, if it is a hash, or a simulation name, if it is
  # non-hash. 
  # 
  def normalize_simulation_identifier *args
    oo = args.extract_options!
    if args.empty? then
      raise AE, "Simulation point position not supplied" if oo.empty?
      oo
    else
      if oo.empty? then
        case args.size
        when 1 then args[0]
        when 4 then Hash[ [:net, :cc, :imc, :ssc].zip( args ) ]
        else raise AE, "Wrong number of ordered arguments." end
      else
        raise AE, "Bad arguments: Can't combine named & ordered args."
      end
    end
  end
end # class YPetri::Manipulator
