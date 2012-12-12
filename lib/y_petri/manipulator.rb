#encoding: utf-8

module YPetri

  # Public command interface of YPetri.
  # 
  class Manipulator

    # Current workspace
    # 
    def workspace; @workspace end

    def initialize
      new_workspace_instance = ::YPetri::Workspace.new
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
    
    delegate :Place, :Transition, :Net,
             :place, :transition,
             :p, :t, :n,
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
    def Place *args; workspace.Place.new *args end

    # Transiton constructor: Creates a new transition in the current workspace.
    # 
    def Transition *args; workspace.Transition.new *args end

    # Net constructor: Creates a new net in the current workspace.
    # 
    def Net *args; workspace.Net.new *args end

    # Sets current net to workspace.Net::Top
    # 
    def net_point_reset
      net_point_to( workspace.Net::Top )
    end

    # Sets current net to the specified net (net instance or name).
    # 
    def net_point_to which_net
      @net_point = workspace.net which_net
    end
    alias :net→ :net_point_to

    # Returns the net at point, or one specified by the argument.
    # 
    def net which=nil
      which.nil? ? @net_point : workspace.net( which )
    end

    # Sets current simulation to the first key of workspace's simulations hash.
    # 
    def simulation_point_reset
      @simulation_point =
        workspace.simulations.empty? ? nil :
          simulation_point_to( workspace.simulations.first[0] )
    end

    # Sets current simulation to the specified simulation.
    def simulation_point_to *aa; oo = aa.extract_options!
      key = if aa.empty? then
              raise AE, "Simulation point position not supplied" if oo.empty?
              oo
            else
              if oo.empty? then
                case aa.size
                when 1 then aa[0]
                when 4 then Hash[ [:net, :cc, :imc, :ssc].zip( aa ) ]
                else raise AE, "Wrong number of ordered arguments." end
              else
                raise AE, "Bad arguments: Can't combine named & ordered args."
              end
            end
      @simulation_point = if key.nil? then nil
                          elsif workspace.simulations.has_key? key then key
                          else raise "No such simulation" end
    end
    alias :sim→ :simulation_point_to


    # Returns simulation at point, or a simulation specified by a key.
    def simulation *aa; oo = aa.extract_options!
      if aa.empty? then
        oo.empty? ? workspace.simulation( @simulation_point ) :
          workspace.simulation( oo )
      else
        if oo.empty? then
          case aa.size
          when 1 then aa[0].nil? ? nil : workspace.simulation( aa[0] )
          when 4 then
            workspace.simulation Hash[ [ :net, :cc, :imc, :ssc ].zip( aa ) ]
          else raise AE, "Wrong number of ordered arguments." end
        else
          raise AE, "Bad arguments: Cannot combine named and ordered args."
        end
      end
    end

    # KLUGE
    def simulation; @workspace.simulations.values[-1] end

    # Returns parameters of the simulation at point
    def simulation_point_position; @simulation_point end

    # --- cc point (cc = clamp collection) ---------------------------------
    # Clamp collections are stored in workplace in a hash. The cc point
    # points to its keys.

    # Resets cc point to :base
    def cc_point_reset; @cc_point = :Base end

    # Sets the cc point to the specified cc.
    def cc_point_to arg
      if workspace.clamp_collections.has_key? arg
        @cc_point = arg
      else raise "No clamp collection #{arg} in this workspace" end
    end
    alias :cc→ :cc_point_to

    # Returns clamp collection corresp. to cc point (if no argument), or to
    # the argument (if this was given).
    def clamp_collection collection_name=nil
      cɴ = collection_name.nil? ? @cc_point : collection_name
      workspace.clamp_collections[ cɴ ] or
        raise AE, "No clamp collection #{cɴ} in this workspace."
    end
    alias :cc :clamp_collection

    # Returns the cc point position (cc hash key)
    def cc_point_position; @cc_point end

    # --- imc point ( imc = initial marking collection ) -------------------
    # Initial marking collections are stored in a workplace in a hash.
    # The imc point points to its keys.

    # Resets imc point to :base
    def imc_point_reset; @imc_point = :Base end

    # Sets the imc point to the specified imc.
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
    def initial_marking_collection collection_name=nil
      cɴ = collection_name.nil? ? @imc_point : collection_name
      workspace.initial_marking_collections[ cɴ ] or
        raise AE, "No initial marking collection #{cɴ} in this workspace."
    end
    alias :imc :initial_marking_collection

    # Returns the ssc point position (ssc hash key)
    def imc_point_position; @imc_point end

    # --- ssc point (ssc = simulation settings collection) -----------------
    # Simulation settings collections are stored in workplace in a hash.
    # The ssc point of manipulator points to its keys.

    # Resets ssc point to :base
    def ssc_point_reset; @ssc_point = :Base end

    # Sets the ssc point to the specified ssc.
    def ssc_point_to arg
      if workspace.simulation_settings_collections.has_key? arg
        @ssc_point = arg
      else raise "No such simulation settings collection: #{arg}" end
    end
    alias :ssc→ :ssc_point_to

    # Returns simulation setting collection corresp. to ssc point (if no
    # argument), or to the argument (if this was given).
    def simulation_settings_collection  collection_name=nil
      cɴ = collection_name.nil? ? @ssc_point : collection_name
      workspace.simulation_settings_collections[ cɴ ] or
        raise AE, "No simulations settings collection #{cɴ} in this workspace."
    end
    alias :ssc :simulation_settings_collection

    # Returns the ssc point position (ssc hash key)
    def ssc_point_position; @ssc_point end


    # ----------------------------------------------------------------------
    # Selection mechanism for net, simulation, cc, imc and ssc

    attr_reader :net_selection, :simulation_selection
    attr_reader :ssc_selection, :cc_selection, :imc_selection

    # --- net selection --------------------------------------------------------------

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

    def initial_marking *args;
      oo = args.extract_options!
      case args.size
      when 0 then
        # no ordered arguments were given
        if oo.empty? then
          # no arguments at all were given - current imc will be returned
          initial_marking_collection
        else
          # hash was supplied as an argument
          # it is assumed that it is a hash of pairs { place_id => marking }
          # and it will be merged with current imc
          initial_marking_collection
            .merge!( oo.with_keys do |key| place( key ) end )
        end
      when 1 then
        # one ordered argument was given
        if oo.empty? then
          # without any other arguments, it is assumed that the one ordered
          # argument represents a place
          place = place( args[0] )
          # and initial marking of this place in the current imc is returned
          initial_marking_collection[ place ]
        else
          # apart from one ordered argument, a hash was given
          # it is assumed that the ordered argument represents an imc
          init_m_coll = initial_marking_collection( args[0] )
          # and imc thus specified is updated with the initial markings
          # spefied in the hash, which is assumed to consist of pairs
          # { place_id => marking }
          init_m_coll.update( oo.with_keys do |key| place( key ) end )
        end
      when 2 then
        # 2 ordered arguments were given
        # it is assumed that the first argument represents an imc
        init_m_coll = initial_marking_collection( args[0] )
        # while the second represents a place
        place = place( args[1] )
        # whose marking is returned
        init_m_coll[ place ]
      else raise AE, "Too many ordered parameters" end
    end
    alias :im :initial_marking

    def set_step Δt; ssc.merge! step_size: Δt end
    alias :set_step_size :set_step

    def set_time t; ssc.merge! target_time: t end
    alias :set_target_time :set_time

    def set_sampling Δt; ssc.merge! sampling_period: Δt end

    def new_timed_simulation *aa
      instance = workspace.new_timed_simulation *aa
      simulation_point_to( simulations.rassoc( instance )[0] )
      return instance
    end

    def run!; new_timed_simulation.run! end

    def print_recording( filename = nil )
      if filename.nil? then
        puts simulation.recording_csv_string
      else
        File.open( filename, "w" ) do |f|
          f << simulation.recording_csv_string
        end
      end
    end

    def plot_recording
      # Get current simulation
      return nil unless sim = @workspace.simulations.values[-1]
      # Simulation time
      ᴛ = simulation.target_time
      # Decide about features to plot
      feature_labels = sim.pp
      feature_time_series = feature_labels
        .map.with_index { |flabel, i|
        sim.recording.map{ |key, val| [ key, val[i] ] }.transpose
      }
      
      gnuplot_recording( ᴛ, feature_labels, feature_time_series )
    end

    def gnuplot_recording( target_time, feature_labels, feature_time_series )
      time_series_labels = feature_labels.dup
      time_series = feature_time_series.dup

      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|
          plot.xrange "[-0:#{target_time}]"
          plot.title "Recording Plot"
          plot.ylabel "marking"
          plot.xlabel "time [s]"

          time_series_labels.zip( time_series ).each { |label, series|
            plot.data << Gnuplot::DataSet.new( series ) do |data_series|
              data_series.with = "linespoints"
              data_series.title = label
            end
          }
        end
      end
    end
  end # class Manipulator
end # module YPetri
