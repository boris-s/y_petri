#encoding: utf-8

# Workspace holds places, transitions, nets and other assets needed for
# simulation (settings, clamps, initial markings etc.). Workspace also
# provides basic methods for their handling, but these are not too public.
# YPetri interface is defined by YPetri::Manipulator.
# 
class YPetri::Workspace
  include NameMagic

  # Workspace-specific place class.
  # 
  attr_reader :Place

  # Workspace-specific transition class.
  # 
  attr_reader :Transition

  # Workspace-specific net class.
  # 
  attr_reader :Net

  attr_reader :clamp_collections,
              :initial_marking_collections,
              :simulation_settings_collections

  def initialize
    # Place subclass specific to this workspace
    @Place = local_place_subclass = Class.new YPetri::Place
    # Transition subclass specific to this workspace
    @Transition = local_transition_subclass = Class.new YPetri::Transition
    # Net subclass specific to this workspace
    @Net = local_net_subclass = Class.new YPetri::Net
    # Let's explain to these new anonymous subclasses that they work together 
    [ @Place, @Transition, @Net ].each { |klass|
      klass.class_exec {
        define_method :Place do local_place_subclass end
        define_method :Transition do local_transition_subclass end
        define_method :Net do local_net_subclass end
        private :Place, :Transition, :Net
      }
    }
    # Create the top net (whole-workspace net).
    @Net.new name: :Top
    # Set hook for new @place to add self automatically to the top net.
    @Place.new_instance_closure { |new_inst| Net()::Top << new_inst }
    # Set hook for new @transition to add self automatically to the top net.
    @Transition.new_instance_closure { |new_inst| Net()::Top << new_inst }
    # A hash of simulations of this workspace { simulation => its settings }.
    @simulations = {}
    # A hash of clamp collections { collection name => clamp hash }.
    @clamp_collections = { Base: {} }
    # A hash of initial marking collections { collection name => init. m. hash }.
    @initial_marking_collections = { Base: {} }
    # A hash of sim. set. collections { collection name => sim. set. hash }.
    @simulation_settings_collections =
      { Base: YPetri::DEFAULT_SIMULATION_SETTINGS.call }
  end

  # Returns a place instance specified by the argument.
  # 
  def place which
    @Place.instance which
  end

  # Returns a transition instance specified by the argument.
  # 
  def transition which
    @Transition.instance which
  end

  # Returns a net instance specified by the argument.
  # 
  def net which
    @Net.instance which
  end

  # Returns the name of a place specified by the argument.
  # 
  def p which
    place( which ).name
  end

  # Returns the name of a transition specified by the argument.
  # 
  def t which
    transition( which ).name
  end

  # Returns the name of a net specified by the argument.
  # 
  def n which
    net( which ).name
  end

  # Places in the workspace.
  # 
  def places
    @Place.instances
  end

  # Transitions in the workspace.
  # 
  def transitions
    @Transition.instances
  end

  # Nets in the workspace.
  # 
  def nets
    @Net.instances
  end

  # Simulations in the workspace.
  # 
  def simulations
    @simulations
  end

  # Names of places in the workspace.
  # 
  def pp
    places.map &:name
  end

  # Names of transitions in the workspace.
  # 
  def tt
    transitions.map &:name
  end

  # Names of nets in the workspace.
  # 
  def nn
    nets.map &:name
  end

  # Names of clamp collections in the workspace.
  # 
  def clamp_cc
    @clamp_collections.keys
  end

  # Names of initial marking collections in the workspace.
  # 
  def initial_marking_cc
    @initial_marking_collections.keys
  end

  # Names of simulation settings collections in the workspace.
  # 
  def simulation_settings_cc
    @simulation_settings_collections.keys
  end

  # Presents a clamp collection specified by the argument.
  # 
  def clamp_collection name=:Base
    @clamp_collections[name]
  end
  alias :cc :clamp_collection

  # Presents a marking collection specified by the argument.
  # 
  def initial_marking_collection name=:Base
    @initial_marking_collections[name]
  end
  alias :imc :initial_marking_collection

  # Presents a simulation settings collection specified by the argument.
  # 
  def simulation_settings_collection name=:Base
    @simulation_settings_collections[name]
  end
  alias :ssc :simulation_settings_collection

  # Creates a clamp collection.
  # 
  def set_clamp_collection( name=:Base, clamp_hash )
    @clamp_collections[name] = clamp_hash
  end
  alias :set_cc :set_clamp_collection

  # Creates an initial marking collection.
  # 
  def set_initial_marking_collection( name=:Base, initial_marking_hash )
    @initial_marking_collections[name] = initial_marking_hash
  end
  alias :set_imc :set_initial_marking_collection

  # Creates a simulation settings collection. Basic simulation settings are:
  # 
  # * step_size: 0.1 by default
  # * sampling_period: 5 by default
  # * target_time: 60 by default
  # 
  def set_simulation_settings_collection( name=:Base, sim_set_hash )
    @simulation_settings_collections[name] = sim_set_hash
  end
  alias :set_ssc :set_simulation_settings_collection

  # Presents a simulation specified by the argument, which must be a hash
  # with four items: (:net, :clamp_collection, :inital_marking_collection and
  # :simulation_settings_collection).
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

  # Makes a new timed simulation. Named arguments are same as for
  # TimedSimulation.new, but in addition, :name named argument can be
  # supplied to serve a name for the simulation in this workspace.
  # 
  # To create a simulation, one must specify which clamp collection, initial
  # marking collection, and which collection of simulation settings to use.
  # A <em>clamp</em>, more specifically, <em>place clamp</em> or <em>marking
  # clamp</em>, means a fixed value, at which the marking of a particular
  # place is held. Similarly, <em>initial marking</em> of a place is the
  # marking held by the place when the simulation starts. For example, having
  # places named "P1".."P5", places "P1" and "P2" could be clamped to marking
  # 4 and 5, written as follows:
  # 
  # * clamps = { P1: 4, P2: 5 }
  #
  # Places "P3", "P4", "P5" are thus <em>free</em>, which means that their
  # initial marking has to be specified (let's say, 1, 2 and 3):
  #
  # * initial_markings = { P3: 1, P4: 2, P5: 3 }
  #
  # As for simulation settings, the 3 common parameters (at least for
  # <tt>YPetri::TimedSimulation</tt> class) are <em>step_size</em>,
  # <em>sampling_period</em>, <em>target_time</em>. For example, default
  # simulation settings are:
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
    # If marking can't be figured, raise beautiful errors.
    missing = im_complement.select { |_, v| v.nil? }
    msg = "Missing clamp and/or initial marking for %s!"
    case missing.size
    when 0 then im_hash = im_hash.merge im_complement # everything's OK
    when 1 then raise TErr, msg % missing.keys[0]
    when 2 then raise TErr, msg % "#{missing.keys[0]} and #{missing.keys[1]}"
    when 3 then raise TErr, msg %
        "#{missing.keys[0]}, #{missing.keys[1]} and #{missing.keys[2]}"
    else raise TErr, msg % ( "#{missing.keys[0]}, #{missing.keys[1]} " +
                           "and #{missing.size - 2} other places" )
    end
    @simulations[ key ] =
      net_ɪ.new_timed_simulation( simulation_settings
                                    .merge( initial_marking: im_hash,
                                            place_clamps: clamp_hash ) )
  end
end # class YPetri::Workspace
