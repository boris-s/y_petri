# -*- coding: utf-8 -*-

module YPetri::Workspace::InstanceMethods
  # Readers for @Place, @Transition, @Net instance variables, which should
  # contain said classes, or their instance-specific subclasses.

  # Place class or parametrized subclass.
  # 
  attr_reader :Place

  # Transition class or parametrized subclass.
  # 
  attr_reader :Transition

  # Net class or parametrized subclass.
  # 
  attr_reader :Net

  # Collections of clamps, initial marking vectors, and simulation settings.
  # 
  attr_reader :clamp_collections,
              :initial_marking_collections,
              :simulation_settings_collections

  # Instance initialization.
  # 
  def initialize
    set_up_Top_net # Sets up :Top net encompassing all places and transitions.

    @simulations = {} # { simulation => its settings }
    @clamp_collections = { Base: {} } # { collection name => clamp hash }
    @initial_marking_collections = { Base: {} } # { collection name => im hash }
    @simulation_settings_collections = # { collection name => ss hash }
      { Base: YPetri::DEFAULT_SIMULATION_SETTINGS.call }
  end

  # Returns a place instance identified by the argument.
  # 
  def place which; Place().instance which end

  # Returns a transition instance identified by the argument.
  # 
  def transition which; Transition().instance which end

  # Returns a net instance identified by the argument.
  # 
  def net which; Net().instance which end

  # Returns the name of a place identified by the argument.
  # 
  def p which; place( which ).name end

  # Returns the name of a transition identified by the argument.
  # 
  def t which; transition( which ).name end

  # Returns the name of a net identified by the argument.
  # 
  def n which; net( which ).name end

  # Place instances.
  # 
  def places; Place().instances end

  # Transition instances.
  # 
  def transitions; Transition().instances end

  # Net instances.
  # 
  def nets; Net().instances end

  # Hash of simulation instances and their settings.
  # 
  def simulations; @simulations end

  # Place names.
  # 
  def pp; places.map &:name end

  # Transition names.
  # 
  def tt; transitions.map &:name end

  # Net names.
  # 
  def nn; nets.map &:name end

  # Clamp collection names.
  # 
  def clamp_collection_names; @clamp_collections.keys end
  alias cc_names clamp_collection_names

  # Initial marking collection names.
  # 
  def initial_marking_collection_names; @initial_marking_collections.keys end
  alias imc_names initial_marking_collection_names

  # Simulation settings collection names.
  # 
  def simulation_settings_collection_names
    @simulation_settings_collections.keys
  end
  alias ssc_names simulation_settings_collection_names

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
  def new_timed_simulation( settings={} ); st = settings
    net_ɪ = net( st[:net] || self.Net::Top )
    cc_id = st.may_have( :cc, syn!: :clamp_collection ) || :Base
    imc_id = st.may_have( :imc, syn!: :initial_marking_collection ) || :Base
    ssc_id = st.may_have( :ssc,  syn!: :simulation_settings_collection ) || :Base

    # simulation key
    key = settings.may_have( :ɴ, syn!: :name ) || # either explicit
      { net: net_ɪ, cc: cc_id, imc: imc_id, ssc: ssc_id } # or constructed

    # Let's clarify what we got so far.
    simulation_settings = self.ssc( ssc_id )
    clamp_hash = self.cc( cc_id )
    im_hash = self.imc( imc_id )

    # Use places' :default_marking in absence of explicit initial marking.
    untreated = net_ɪ.places.select do |p|
      ! clamp_hash.map { |k, _| place k }.include? p and
      ! im_hash.map { |k, _| place k }.include? p
    end
    im_complement = Hash[ untreated.zip( untreated.map &:default_marking ) ]

    # If marking can't be figured, raise nice errors.
    missing = im_complement.select { |_, v| v.nil? }
    err = lambda { |array, txt=''|
      raise TypeError, "Missing clamp and/or initial marking for %s#{txt}!" %
      Array( array ).map { |i| missing.keys[i] }.join( ', ' )
    }
    case missing.size
    when 0 then im_hash = im_hash.merge im_complement # everything's OK
    when 1 then err.( 0 )
    when 2 then err.( [0, 1] )
    when 3 then err.( [0, 1, 2] )
    else err.( [0, 1], " and #{missing.size-2} more places" ) end

    # Finally, create and return the simulation
    @simulations[ key ] =
      net_ɪ.new_timed_simulation( simulation_settings
                                    .merge( initial_marking: im_hash,
                                            place_clamps: clamp_hash ) )
  end # def new_timed_simulation

  private

  # Creates all-encompassing Net instance named :Top.
  # 
  def set_up_Top_net
    Net().new name: :Top # all-encompassing :Top net
    # Hook new places to add themselves magically to the :Top net.
    Place().new_instance_closure { |new_inst| net( :Top ) << new_inst }
    # Hook new transitions to add themselves magically to the :Top net.
    Transition().new_instance_closure { |new_inst| net( :Top ) << new_inst }    
  end
end # module YPetri::Workspace::InstanceMethods
