# encoding: utf-8

# Agent instance methods related to simulation (initial marking collections,
# clamp collections, initial marking collections, management of simulations...)
# 
module YPetri::Agent::SimulationRelated
  require_relative 'hash_key_pointer'
  require_relative 'selection'

  # Simulation selection class.
  # 
  SimulationSelection = YPetri::Agent::Selection.parametrize( agent: self )

  # Simulation settings collection selection class.
  # 
  SscSelection = YPetri::Agent::Selection.parametrize( agent: self )

  # Clamp collection selection class.
  # 
  CcSelection = YPetri::Agent::Selection.parametrize( agent: self )

  # Initial marking collection selection class.
  # 
  ImcSelection = YPetri::Agent::Selection.parametrize( agent: self )

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
  SscPoint = YPetri::Agent::HashKeyPointer.parametrize( agent: self )

  # Pointer to a clamp collection.
  # 
  CcPoint = YPetri::Agent::HashKeyPointer.parametrize( agent: self )

  # Pointer to a collection of initial markings.
  # 
  ImcPoint = YPetri::Agent::HashKeyPointer.parametrize( agent: self )

  attr_reader :simulation_point,
              :ssc_point,
              :cc_point,
              :imc_point,
              :simulation_selection,
              :ssc_selection,
              :cc_selection,
              :imc_selection

  # Agent initialziation method.
  # 
  def initialize
    # set up this agent's pointers
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

  # Simulation-related methods delegated to the world.
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
           :new_simulation, :clamp_cc,
           :initial_marking_cc, :simulation_settings_cc,
           to: :world

  delegate :pm,
           :recording,
           to: :simulation

  # Pretty print the state.
  # 
  def state
    pp pm
    return nil
  end

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
      clamp_collection.merge! world.place( place ) => clamp
    end
  end

  # Returns or modifies current initial marking(s) as indicated by the argument
  # field:
  # 
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
    ssc.update step: Δt
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
    ssc.update sampling: Δt
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
    instance = world.new_simulation( *args, &block )
    # Set the point to it
    simulation_point.set( simulations.rassoc( instance )[0] )
    return instance
  end

  # Create a new timed simulation and run it.
  # 
  def run! *args
    new_simulation.run! *args
  end

  # Write the recorded samples in a file (csv).
  # 
  def print_recording( filename=nil, **nn )
    if filename.nil? then
      simulation.recording.print **nn
    else
      File.open filename, "w" do |f| f << print_recording( **nn ) end
    end
  end

  # Plot the recording reduced into the given feature set.
  # 
  def plot features
    ff = simulation.net.state.features( features )
    simulation.recording.reduce_features( ff ).plot
  end

  # Plot system state history.
  # 
  def plot_marking( place_ids=nil, except: [],
                  title: "State plot", ylabel: "Marking [µM]",
                  **options )
    rec = simulation.recording
    pp = simulation.pp( place_ids ) - simulation.pp( except )
    rec.marking( pp ).plot( title: title, ylabel: ylabel, **options )
  end
  alias plot_state plot_marking

  # Plot flux history of TS transitions.
  # 
  def plot_flux( transition_ids=nil, except: [],
                 title: "Flux plot", ylabel: "Flux [µM.s⁻¹]",
                 **options )
    rec = simulation.recording
    tt = transition_ids.nil? ? simulation.TS_tt : transition_ids
    tt = simulation.TS_tt( tt )
    tt -= simulation.tt( except )
    rec.flux( tt ).plot( title: title, ylabel: ylabel, **options )
  end

  # Plot firing history of tS transitions.
  # 
  def plot_firing( transition_ids=nil, except: [],
                   title: "Firing plot", ylabel: "Firing [µM]",
                   **options )
    rec = simulation.recording
    tt = transition_ids.nil? ? simulation.tS_tt : transition_ids
    tt = simulation.tS_tt( tt )
    tt -= simulation.tt( except )
    rec.firing( tt ).plot( title: title, ylabel: ylabel, **options )
  end

  # Plot gradient history of selected places with respect to a set of T
  # transitions.
  # 
  def plot_gradient( place_ids=nil, except: [], transitions: nil,
                     title: "Gradient plot", ylabel: "Gradient [µM.s⁻¹]",
                     **options )
    rec = simulation.recording
    pp = simulation.pp( place_ids ) - simulation.ee( place_ids )
    tt = transitions.nil? ? simulation.T_tt : transitions
    tt = simulation.T_tt( tt )
    tt -= simulation.ee( except )
    rec.gradient( pp, transitions: tt )
      .plot( title: title, ylabel: ylabel, **options )
  end

  # Plot delta history of selected places with respect to a set of transitions.
  # 
  def plot_delta( place_ids=nil, except: [], transitions: nil,
                  title: "Delta plot", ylabel: "Delta [µM]",
                  **options )
    options.may_have :delta_time, syn!: :Δt
    rec = simulation.recording
    pp = simulation.pp( place_ids ) - simulation.ee( except )
    tt = transitions.nil? ? simulation.tt : transitions
    tt = simulation.tt( tt )
    tt -= simulation.ee( except )
    rec.delta( pp, transitions: tt, Δt: options[:delta_time] )
      .plot( title: title, ylabel: ylabel, **options )
  end

  # # Pretty print marking of the current simulation.
  # # 
  # def marking
    
  # end
  # alias state marking

  # # Pretty print the flux for the current simulation state.
  # # 
  # def flux
    
  # end

  # # Pretty print the firing for the current simulation state.
  # # 
  # def firing
    
  # end

  # # Pretty print the gradient for the current simulation state.
  # # 
  # def gradient
    
  # end

  # # Pretty print deltas for the current simulation state.
  # # 
  # def delta( place_ids=nil, except: [], transitions: nil, **options )
  #   Δt = options.must_have :delta_time, syn!: :Δt
  #   pp = simulation.pp( place_ids )
  #   tt = transitions.nil? ? simulation.tt : transitions
  #   simulation.delta( place_id, except: except, transitions: transitions )
  # end
end # module YPetri::Agent::SimulationRelated
