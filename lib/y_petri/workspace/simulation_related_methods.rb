# encoding: utf-8

# Workspace instance methods related to simulation (initial marking collections,
# clamp collections, inital marking collections, management of simulations...)
# 
module YPetri::Workspace::SimulationRelatedMethods
  # Collections of clamps, initial marking vectors, and simulation settings.
  # 
  attr_reader :clamp_collections,
              :initial_marking_collections,
              :simulation_settings_collections

  # Instance initialization.
  # 
  def initialize
    @simulations = {} # { simulation => its settings }
    @clamp_collections = { Base: {} } # { collection name => clamp hash }
    @initial_marking_collections = { Base: {} } # { collection name => im hash }
    @simulation_settings_collections = # { collection name => ss hash }
      { Base: YPetri::DEFAULT_SIMULATION_SETTINGS.call }
    super
  end

  # Hash of simulation instances and their settings.
  # 
  def simulations
    @simulations
  end

  # Clamp collection names.
  # 
  def clamp_collection_names
    @clamp_collections.keys
  end
  alias ncc clamp_collection_names

  # Initial marking collection names.
  # 
  def initial_marking_collection_names
    @initial_marking_collections.keys
  end
  alias nimc initial_marking_collection_names

  # Simulation settings collection names.
  # 
  def simulation_settings_collection_names
    @simulation_settings_collections.keys
  end
  alias nssc simulation_settings_collection_names

  # Clamp collection identified by the argument.
  # 
  def clamp_collection name=:Base
    @clamp_collections[name]
  end
  alias cc clamp_collection

  # Marking collection identified by the argument.
  # 
  def initial_marking_collection name=:Base
    @initial_marking_collections[name]
  end
  alias imc initial_marking_collection

  # Simulation settings collection specified by the argument.
  # 
  def simulation_settings_collection name=:Base
    @simulation_settings_collections[name]
  end
  alias ssc simulation_settings_collection

  # Creates a new clamp collection. If collection identifier is not given,
  # resets :Base clamp collection to new values.
  # 
  def set_clamp_collection( name=:Base, clamp_hash )
    @clamp_collections[name] = clamp_hash
  end
  alias set_cc set_clamp_collection

  # Creates a new initial marking collection. If collection identifier is not
  # given, resets :Base initial marking collection to new values.
  # 
  def set_initial_marking_collection( name=:Base, initial_marking_hash )
    @initial_marking_collections[name] = initial_marking_hash
  end
  alias set_imc set_initial_marking_collection

  # Creates a new simulation settings collection. If collection identifier is
  # not given, resets :Base simulation settings collection to new values.
  # 
  def set_simulation_settings_collection( name=:Base, sim_set_hash )
    @simulation_settings_collections[name] = sim_set_hash
  end
  alias set_ssc set_simulation_settings_collection

  # Presents a simulation specified by the argument, which must be a hash with
  # four items: :net, :clamp_collection, :inital_marking_collection and
  # :simulation_settings_collection.
  # 
  def simulation settings={}
    key = case settings
          when ~:may_have then # it is a hash or equivalent
            settings.may_have :net
            settings.may_have :cc, syn!: :clamp_collection
            settings.may_have :imc, syn!: :initial_marking_collection
            settings.may_have :ssc, syn!: :simulation_settings_collection
            { net:  net( settings[:net] || self.Net::Top ), # the key
              cc:   settings[:cc]       || :Base,
              imc:  settings[:imc]      || :Base,
              ssc:  settings[:ssc]      || :Base }
          else # use the unprocessed argument itself as the key
            settings
          end
    @simulations[ key ]
  end

  # Makes a new timed simulation. Named arguments for this method are the same
  # as for TimedSimulation#new, but in addition, :name can be supplied.
  # 
  # To create a simulation, simulation settings collection, initial marking
  # collection, and clamp collection have to be specified. A <em>place clamp</em>,
  # is a fixed value, at which the marking is held. Similarly, <em>initial
  # marking</em> is the marking, which a free place receives at the beginning.
  # Free places are those, that are not clamped. After initialization, marking
  # of free places is allowed to change as the transition fire.
  # 
  # For example, having places :P1..:P5, clamped :P1, :P2 can be written as eg.:
  # 
  # * clamps = { P1: 4, P2: 5 }
  #
  # Places :P3, :P4, :P5 are <em>free</em>. Their initial marking has to be
  # specified, which can be written as eg.:
  #
  # * initial_markings = { P3: 1, P4: 2, P5: 3 }
  #
  # As for simulation settings, their exact nature depends on the simulation
  # method. For default Euler method, there are 3 important parameters:
  #   - <em>step_size</em>,
  #   - <em>sampling_period</em>,
  #   - <em>target_time</em>
  #   
  # For example, default simulation settings are:
  #
  # * default_ss = { step_size: 0.1, sampling_period: 5, target_time: 60 }
  # 
  def new_simulation( net: Net()::Top, **nn )
    net_inst = net( net )
    nn.may_have :cc, syn!: :clamp_collection
    nn.may_have :imc, syn!: :initial_marking_collection
    nn.may_have :ssc, syn!: :simulation_settings_collection
    cc_id = nn.delete( :cc ) || :Base
    imc_id = nn.delete( :imc ) || :Base
    ssc_id = nn.delete( :ssc ) || :Base
    # Construct the simulation key:
    key = if nn.has? :name, syn!: :ɴ then # explicit key (name)
            nn[:name]
          else                       # constructed key
            {}.merge( net: net_inst,
                       cc: cc_id,
                       imc: imc_id,
                       ssc: ssc_id )
              .merge( nn )
          end
    # Let's clarify what we got so far.
    sim_settings = ssc( ssc_id )
    mc_hash = cc( cc_id )
    im_hash = imc( imc_id )
    # Create and return the simulation
    sim = net_inst.simulation **sim_settings.merge( initial_marking: im_hash,
                                                    marking_clamps: mc_hash
                                                    ).merge( nn )
    @simulations[ key ] = sim
  end
end # module YPetri::Workspace::SimulationRelatedMethods
