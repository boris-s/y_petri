# Selections of various kinds of places / transitions (place names / transition
# names) in a Petri net.
# 
module YPetri::Net::NodeAccess
  # Does the net include a place?
  # 
  def includes_place? id
    begin
      place( id ) and true
    rescue NameError, TypeError; false end
  end
  alias include_place? includes_place?

  # Does the net include a transition?
  # 
  def includes_transition? id
    begin; transition( id ) and true; rescue NameError, TypeError; false end
  end
  alias include_transition? includes_transition?

  # Inquirer whether the net includes a node.
  # 
  def include? id
    include_place?( id ) || include_transition?( id )
  end
  alias includes? include?

  # Returns the net's place identified by the argument.
  # 
  def place id
    ( super rescue Place().instance( id ) ).tap do |p|
      fail TypeError, "No place #{id} in the net!" unless places.include? p
    end
  end

  # Returns the net's transition identified by the argument.
  # 
  def transition id
    ( super rescue Transition().instance( id ) ).tap do |t|
      transitions.include? t or fail TypeError, "No transition #{id} in the net!"
    end
  end

  # Returns the net's node identified by the argument.
  # 
  def node id
    begin; place( id ); rescue NameError, TypeError
      begin; transition( id ); rescue NameError, TypeError
        raise TypeError, "The net does not include node #{id}!"
      end
    end
  end

  # Expects an array of nodes (places/transitions) or node ids, and returns
  # an array of corresponding node instances.
  # 
  def Nodes array
    array.map &method( :node )
  end

  # Expects an arbitrary number of nodes (places/transitions) or node ids and
  # returns an array of corresponding node instances. If no arguments are
  # supplied, returns all net's places and transitions.
  # 
  def nodes *nodes
    return @places + @transitions if nodes.empty?
    Nodes( nodes )
  end
  alias nn nodes

  # Expects an array of places or place ids, and returns an array of
  # corresponding place instances.
  # 
  def Places array
    array.map &method( :place )
  end

  # Expects an arbitrary number of places or place ids and returns an array of
  # corresponding place instances. If no arguments are supplied, returns all
  # net's places.
  # 
  def places *places
    return @places.dup if places.empty?
    Places( places )
  end
  alias pp places

  # Expects an array of transitions or transition ids, and returns an array of
  # corresponding transition instances.
  # 
  def Transitions array
    array.map &method( :transition )
  end

  # Expects an arbitrary number of transitions or transition ids and returns
  # an array of corresponding transition instances. If no arguments are supplied,
  # returns all net's transitions.
  # 
  def transitions *transitions
    return @transitions.dup if transitions.empty?
    Transitions( transitions )
  end
  alias tt transitions

  # Expects an array of *ts* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def ts_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be ts", &:ts?
  end

  # Expects an arbitrary number of *ts* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def ts_transitions *transitions
    return transitions().select &:ts? if transitions.empty?
    ts_Transitions( transitions )
  end
  alias ts_tt ts_transitions

  # Expects an array of *tS* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def tS_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be tS", &:tS?
  end

  # Expects an arbitrary number of *tS* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def tS_transitions *transitions
    return transitions().select &:tS? if transitions.empty?
    tS_Transitions( transitions )
  end
  alias tS_tt tS_transitions

  # Expects an array of *Ts* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def Ts_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be Ts", &:Ts?
  end

  # Expects an arbitrary number of *Ts* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def Ts_transitions *transitions
    return transitions().select &:Ts? if transitions.empty?
    Ts_Transitions( transitions )
  end
  alias Ts_tt Ts_transitions

  # Expects an array of *TS* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def TS_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be TS", &:TS?
  end

  # Expects an arbitrary number of *TS* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def TS_transitions *transitions
    return transitions().select &:TS? if transitions.empty?
    TS_Transitions( transitions )
  end
  alias TS_tt TS_transitions

  # Expects an array of *A* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def A_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be A", &:A?
  end

  # Expects an arbitrary number of *A* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def A_transitions *transitions
    return transitions().select &:A? if transitions.empty?
    A_Transitions( transitions )
  end
  alias A_tt A_transitions

  # Expects an array of *a* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def a_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be a", &:a?
  end

  # Expects an arbitrary number of *a* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def a_transitions *transitions
    return transitions().select &:a? if transitions.empty?
    a_Transitions( transitions )
  end
  alias a_tt a_transitions

  # Expects an array of *S* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def S_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be S", &:S?
  end

  # Expects an arbitrary number of *S* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def S_transitions *transitions
    return transitions().select &:S? if transitions.empty?
    S_Transitions( transitions )
  end
  alias S_tt S_transitions

  # Expects an array of *s* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def s_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be s", &:s?
  end

  # Expects an arbitrary number of *s* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def s_transitions *transitions
    return transitions().select &:s? if transitions.empty?
    s_Transitions( transitions )
  end
  alias s_tt s_transitions

  # Expects an array of *T* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def T_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be T", &:T?
  end

  # Expects an arbitrary number of *T* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def T_transitions *transitions
    return transitions().select &:T? if transitions.empty?
    T_Transitions( transitions )
  end
  alias T_tt T_transitions

  # Expects an array of *t* transitions or transition ids, and returns an array
  # of corresponding transition instances.
  # 
  def t_Transitions array
    Transitions( array ).aT_all "transition identifiers", "be t", &:t?
  end

  # Expects an arbitrary number of *t* transitions or transition ids as
  # arguments, and returns an array of corresponding transition instances.
  # 
  def t_transitions *transitions
    return transitions().select &:t? if transitions.empty?
    t_Transitions( transitions )
  end
  alias t_tt t_transitions

  # Name-returning versions of the node access methods.
  # 
  chain nNn: :Nodes,
        nnn: :nodes,
        nPp: :Places,
        npp: :places,
        nTt: :Transitions,
        ntt: :transitions,
        nts: :ts_transitions,
        ntS: :tS_transitions,
        nTs: :Ts_transitions,
        nTS: :TS_transitions,
        nA: :A_transitions,
        na: :a_transitions,
        nS: :S_transitions,
        ns: :s_transitions,
        nT: :T_transitions,
        nt: :t_transitions do |nodes| nodes.names end
end # class YPetri::Net::NodeAccess
