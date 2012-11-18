#encoding: utf-8

# Public command interface of YPetri.

module YPetri
  class Manipulator
    attr_reader :workspace
    
    def note_new_Petri_net_object_instance( i )
      workspace << i rescue warn "Instance rejected by the workspace!"
    end

    def initialize
      @workspace = ::YPetri::Workspace.new
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

    delegate :places, :transitions, :nets, :simulations,
             :clamp_collections,
             :initial_marking_collections,
             :simulation_settings_collections,
             :pp, :tt, :nn,
             :ccc, :imcc, :sscc,
             to: :workspace

    # ---------------------------------------------------------------------
    # Point (cursor) for net, simulation, cc, imc and ssc.

    # --- net point --------------------------------------------------------
    # Net instances are stored in ::YPetri::Workspace nets array. The
    # instances themselves can have name.

    # Sets net point to worspace's top net.
    def net_point_reset; net_point_to workspace.net end

    # Sets the net point to the specified net (net instance or name).
    def net_point_to arg; @net_point = workspace.net arg end
    alias :net→ :net_point_to

    # Returns the net at point, or specified by the argument.
    def net arg=ℒ(); arg.ℓ? ? @net_point : workspace.net( arg ) end

    # Returns the net point position (nets array index)
    def net_point_position; workspace.nets.index( @net_point ) end

    # --- simulation point -------------------------------------------------
    # Simulation instances in the workspace are stored in @simulations hash
    # of key => instance pairs. The key can be either specified by the
    # caller (as first ordered parameter of Workspace#new_timed_simulation
    # method), or it will be constructed automatically by the said method
    # using simulation settings. Simulation point then refers to this key.
    # Simulation instances themselves do not have name.

    # Sets the simulation point to the first key of workspace's simulations.
    def simulation_point_reset
      @simulation_point = workspace.simulations.empty? ? nil :
        simulation_point_to( workspace.simulations.first[0] )
    end

    # Shifts simulation point
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
    def cc_point_reset; @cc_point = :base end

    # Sets the cc point to the specified cc.
    def cc_point_to arg
      if workspace.clamp_collections.has_key? arg
        @cc_point = arg
      else raise "No clamp collection #{arg} in this workspace" end
    end
    alias :cc→ :cc_point_to

    # Returns clamp collection corresp. to cc point (if no argument), or to
    # the argument (if this was given).
    def clamp_collection arg=ℒ()
      workspace.clamp_collections[ arg.ℓ? ? @cc_point : arg ] or
        raise AE, "No clamp collection #{arg} in this workspace."
    end
    alias :cc :clamp_collection

    # Returns the cc point position (cc hash key)
    def cc_point_position; @cc_point end

    # --- imc point ( imc = initial marking collection ) -------------------
    # Initial marking collections are stored in a workplace in a hash.
    # The imc point points to its keys.

    # Resets imc point to :base
    def imc_point_reset; @imc_point = :base end

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
    def initial_marking_collection arg=ℒ()
      workspace.initial_marking_collections[ arg.ℓ? ? @imc_point : arg ] or
        raise AE, "No initial marking collection #{arg} in this workspace."
    end
    alias :imc :initial_marking_collection

    # Returns the ssc point position (ssc hash key)
    def imc_point_position; @imc_point end

    # --- ssc point (ssc = simulation settings collection) -----------------
    # Simulation settings collections are stored in workplace in a hash.
    # The ssc point of manipulator points to its keys.

    # Resets ssc point to :base
    def ssc_point_reset; @ssc_point = :base end

    # Sets the ssc point to the specified ssc.
    def ssc_point_to arg
      if workspace.simulation_settings_collections.has_key? arg
        @ssc_point = arg
      else raise "No such simulation settings collection: #{arg}" end
    end
    alias :ssc→ :ssc_point_to

    # Returns simulation setting collection corresp. to ssc point (if no
    # argument), or to the argument (if this was given).
    def simulation_settings_collection arg=ℒ()
      workspace.simulation_settings_collections[ arg.ℓ? ? @ssc_point : arg ] or
        raise AE, "No simulations settings collection #{arg} in this workspace."
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

    def place *aa, &b; workspace.new_place *aa, &b end
    def transition *aa, &b; workspace.new_transition *aa, &b end

    def p arg
      instance = workspace.place arg
      arg.kind_of?( ::YPetri::Place ) ? instance.name : instance
    end

    def t arg
      instance = workspace.transition arg
      arg.kind_of?( ::YPetri::Transition ) ? instance.name : instance
    end

    def clamp *aa; oo = aa.extract_options!
      if aa.empty? then # oo contains place => clamp pairs
        oo.each_pair { |pl, cl|
          clamp_collection.merge! workspace.place( pl ) => cl
        }
      else # aa is expected to consist of 2 params: place and clamp
        raise AE, "If ordered parameters are given, their number must be 2" unless
          aa.size == 2
        clamp_collection.merge! workspace.place( aa[0] ) => aa[1]
      end
    end
    
    def initial_marking *aa; oo = aa.extract_options!
      case aa.size
      when 0 then
        if oo.empty? then imc else
          imc.merge!( oo.with_keys do |k| ::YPetri::Place k end )
        end
      when 1 then
        if oo.empty? then
          begin
            imc[ ::YPetri::Place aa[0] ]
          rescue
            imc aa[0]
          end
        else
          imc( aa[0] ).update oo.with_keys do |k| ::YPetri::Place k end
        end
      when 2 then
        begin
          imc[ ::YPetri::Place aa[0] ] = aa[1] # LATER: Taking a parameter here
        rescue
          imc( aa[0] )[ ::YPetri::Place aa[1] ]
        end
      when 3 then
        imc( aa[0] )[ ::YPetri::Place aa[1] ] = aa[2]
      else raise AE, "Too many ordered parameters" end
    end
    alias :im :initial_marking

    def set_step Δt; ssc.merge! step_size: Δt end

    def set_time t; ssc.merge! target_time: t end

    def set_sampling Δt; ssc.merge! sampling_period: Δt end

    def new_timed_simulation *aa
      instance = workspace.new_timed_simulation *aa
      simulation_point_to( simulations.rassoc( instance )[0] )
      return instance
    end

    def run!; new_timed_simulation.run! end

    def print_recording( filename = nil )
      if filename.nil? then
        simulation.print_recording
      else
        File.open( filename, "w" ) do |f|
          f << simulation.print_recording
        end
      end
    end

    def plot_recording
      return nil unless @workspace.simulations.values[-1]
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|
          plot.xrange "[-0:30]"
          plot.title "Recording Plot Example"
          plot.ylabel "marking"
          plot.xlabel "time"
          
          titles = workspace.simulation.pp
          (0...titles.size).each{ |i|
            to_plot = @workspace.simulations.values[-1].recording.map{ |key, val| [key, val[i]] }.transpose
            plot.data << Gnuplot::DataSet.new( to_plot ) do |ds|
              ds.with = "linespoints"
              ds.title = titles.shift
            end
          }
        end
      end
    end
  end # class Manipulator
end # module YPetri
