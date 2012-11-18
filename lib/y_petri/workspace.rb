#encoding: utf-8

# Workspace holds places, transitions, nets and other assets needed for
# simulation (settings, clamps, initial markings etc.). It has basic methods
# to handle creation of places, transitions and other mentioned
# assets. Workspace interface is not considered too public; it is used
# mainly by Manipulator to create convenient public interface.

module YPetri
  class Workspace
    attr_reader :clamp_collections,
    :initial_marking_collections,
    :simulation_settings_collections
    
    alias :c_collections :clamp_collections
    alias :im_collections :initial_marking_collections
    alias :ss_collections :simulation_settings_collections

    def initialize
      @places = Array.new
      @transitions = Array.new
      @nets = [ Net.new ]
      @simulations = {}
      @clamp_collections = { base: {} }
      @initial_marking_collections = { base: {} }
      @simulation_settings_collections = { base: DEFAULT_SIMULATION_SETTINGS }
    end

    attr_reader :places, :transitions, :nets, :simulations

    def pp; places.map &:name end
    def tt; transitions.map &:name end
    def nn; nets.map &:name end

    def ccc; @clamp_collections.keys end
    def imcc; @initial_marking_collections.keys end
    def sscc; @simulation_settings_collections.keys end

    # Presents a clamp collection specified by the argument
    def clamp_collection id=:base; @clamp_collections[id] end
    alias :cc :clamp_collection

    # Presents a marking collection specified by the argument
    def initial_marking_collection id=:base
      @initial_marking_collections[id] end
    alias :imc :initial_marking_collection

    # Presents a collection of simulation settings spec. by the argument
    def simulation_settings_collection id=:base
      @simulation_settings_collections[id] end
    alias :ssc :simulation_settings_collection

    # Sets the clamp collection whose id is given as the first argument to
    # be equal to the hash supplied as the second argument.
    def set_clamp_collection id=:base, hsh
      @clamp_collections[id] = hsh.aE_kind_of Hash
    end
    alias :set_cc :set_clamp_collection

    # Sets the initial marking collection whose id is given as the first
    # argument to be equal to the hash supplied as the second argument.
    def set_initial_marking_collection id=:base, hsh
      @initial_marking_collections[id] = hsh.aE_kind_of Hash
    end
    alias :set_imc :set_initial_marking_collection

    # Sets the collection of simulation settings whose id is given as the
    # first argument to be equal to the hash supplied as the second argument.
    def set_simulation_settings_collection id=:base, hsh
      @simulation_settings_collections[id] = hsh.aE_kind_of Hash
    end
    alias :set_ssc :set_simulation_settings_collection

    # Presents a simulation specified by the argument, which must be a hash
    # with four items: :net, 
    def simulation *aa; oo = aa.extract_options!
      oo.may_have :net, syn!: :n
      net_instance = net( oo[:net] || net )
      cc_id = oo.may_have( :clamp_collection, syn!: :cc ) || :base
      imc_id = oo.may_have( :initial_marking_collection, syn!: :imc ) || :base
      ssc_id = oo.may_have( :simulation_settings_collection, syn!: :ssc ) || :base
      key = if aa.empty? then
              { net: net_instance, cc: cc_id, imc: imc_id, ssc: ssc_id }
            elsif aa.size > 1 then raise AE, "Too many parameters"
            else key = aa[0] end
      simulations[ key ]
    end

    # Makes a new timed simulation. Named arguments are same as for
    # TimedSimulation.new, but in addition, one ordered argument can be
    # supplied to serv as a key in the workspace list of simulations.
    def new_timed_simulation *aa; oo = aa.extract_options!
      oo.may_have( :net, syn!: :n )
      net_instance = net( oo[:net] || net )
      cc_id = oo.may_have( :clamp_collection, syn!: :cc ) || :base
      imc_id = oo.may_have( :initial_marking_collection, syn!: :imc ) || :base
      ssc_id = oo.may_have( :simulation_settings_collection, syn!: :ssc ) ||
        :base
      key = if aa.empty? then
              { net: net_instance, cc: cc_id, imc: imc_id, ssc: ssc_id }
            elsif aa.size > 1 then raise AE, "Too many parameters"
            else key = aa[0] end
      args = ssc( ssc_id ).merge( initial_marking: imc( imc_id ),
                        place_clamps: cc( cc_id ) )
      # Create a new simulation instance
      instance = net_instance.new_timed_simulation args
      # Make a reference to it from the simulations collection
      simulations[ key ] = instance
    end

    # Creates a new place in the workspace, arguments as Place.new
    def new_place *aa, &b; include_place! ::YPetri::Place.new *aa, &b end

    # Includes an existing place in the workspace
    def include_place! instance; instance.aE_is_a ::YPetri::Place
      ɴ = instance.name
      raise "Another place named #{ɴ} already in this workspace!" unless
        places.select { |p| p.name == ɴ && p != instance }.empty?
      places << instance unless places.include? instance
      raise "Another place named #{ɴ} already in the top net!" unless
        net.places.select { |p| p.name == ɴ && p != instance }.empty?
      net << instance unless @nets.include? instance
      # Let us notice the default marking into :base collection, if given
      imc( :base ).update( instance => instance.default_marking ) if
        instance.default_marking
      return instance
    end

    # Creates a new transition in the workspace, arguments as Transition.new
    def new_transition *aa, &b
      include_transition! ::YPetri::Transition.new *aa, &b
    end

    # Includes an existing transition in the workspace
    def include_transition! instance; instance.aE_is_a ::YPetri::Transition
      ɴ = instance.name
      raise "Another transition named #{ɴ} already in this workspace!" unless
        transitions.select { |t| t.name == ɴ && t != instance }.empty?
      transitions << instance unless transitions.include? instance
      raise "Another transition named #{ɴ} already in the top net!" unless
        net.transitions.select { |t| t.name == ɴ && t != instance }.empty?
      # Top net relied upon to check legality of the transition's arcs
      net << instance unless nets.include? instance
      return instance
    end

    # Creates a new net in the workspace, arguments as Net.new
    def new_net *aa, &b; include_net! ::YPetri::Net.new *aa, &b end

    # Includes an existing net int the workspace
    def include_net! instance; instance.aE_is_a ::YPetri::Net
      ɴ = instance.name
      raise "Another net named #{ɴ} already in this workspace!" unless
        nets.select { |n| n.name = ɴ && t != instance }.empty?
      nets << instance unless nets.include? instance
      return instance
    end

    # Includes an object in the workspace
    def << o
      case o
      when ::YPetri::Place then include_place! o
      when ::YPetri::Transition then include_transition! o
      when ::YPetri::Net then include_net! o
      else raise "unexpected argument class: #{o}" end
    end      

    # Access to the workspace's nets. If not net is specified in the argument,
    # default (top) net of the workspace is returned.
    def net arg=ℒ()
      return @nets.first if arg.ℓ?
      @nets[arg] rescue nets.include?( i = ::YPetri::Net( arg ) ) ? i : nil
    end

    # Safe access of place instances
    def place arg
      case arg
      when ::YPetri::Place then
        if places.include? arg then arg else
          raise AE, "Place #{arg} not in this workspace." end
      when String, Symbol then
        if pp.include? arg.to_s then
          selection = places.select { |p| p.name == arg.to_s }
          raise "More than one place with name '#{arg}'" +
            "exists in this workspace" if selection.size > 1
          selection.first
        else raise AE, "Place named #{arg} not included in this workspace." end
      else raise AE, "Unexpected argument class: #{arg.class}." end
    end

    # Safe access of place names
    def p arg; place( arg ).name end

    # Safe access of transition instances
    def transition arg
      case arg
      when ::YPetri::Transition then
        if transitions.include? arg then arg else
          raise AE, "Transition #{arg} not included in this workspace." end
      when String, Symbol then
        if tt.include? arg.to_s then
          selection = transitions.select { |t| t.name == arg.to_s }
          raise "More than one transition with name '#{arg}'" +
            "exists in this workspace" if selection.size > 1
          selection.first
        else
          raise AE, "Transition named #{arg} not included in this workspace."
        end
      else
        raise AE, "Unexpected argument class: #{arg.class}."
      end
    end

    # Safe access of transition names
    def t arg; transition( arg ).name end
  end # class Workspace
end # module YPetri
