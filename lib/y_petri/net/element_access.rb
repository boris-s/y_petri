# Selections of various kinds of places / transitions (place names / transition
# names) in a Petri net.
# 
module YPetri::Net::ElementAccess
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

  # Inquirer whether the net includes an element.
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

  # Returns the net's element identified by the argument
  # 
  def element id
    begin; place( id ); rescue NameError, TypeError
      begin; transition( id ); rescue NameError, TypeError
        raise TypeError, "The net does not include place/transition #{id}!"
      end
    end
  end

  # Returns the net's elements identified by the argument's elements.
  # 
  def elements ids=nil
    return @places + @transitions if ids.nil?
    ids.map { |id| element id }
  end

  # Returns the names of the net's elements identified by the array.
  # 
  def en ids=nil
    elements( ids ).names
  end

  # Returns the net's places identified by the argument's elements.
  # 
  def places ids=nil
    return @places.dup if ids.nil?
    ids.map { |id| place id }
  end
  alias pp places

  # Returns the net's transitions identified by the argument's elements.
  # 
  def transitions ids=nil
    return @transitions.dup if ids.nil?
    ids.map { |id| transition id }
  end
  alias tt transitions

  # Names of places in the net.
  # 
  def pn ids=nil
    places( ids ).names
  end

  # Names of transitions in the net.
  # 
  def tn ids=nil
    transitions( ids ).names
  end

  # *ts* transitions.
  # 
  def ts_transitions ids=nil
    return transitions.select &:ts? if ids.nil?
    transitions( ids ).aT_all "transition identifiers", "be ts", &:ts?
  end

  # Names of *ts* transitions.
  # 
  def nts ids=nil
    ts_transitions( ids ).names
  end

  # *tS* transitions.
  # 
  def tS_transitions ids=nil
    return transitions.select &:tS? if ids.nil?
    transitions( ids ).aT_all "transition identifiers", "be tS", &:tS?
  end

  # Names of *tS* transitions.
  # 
  def ntS ids=nil
    tS_transitions( ids ).names
  end

  # *Ts* transitions.
  # 
  def Ts_transitions ids=nil
    return transitions.select &:Ts? if ids.nil?
    transitions( ids ).aT_all "transition identifiers", "be Ts", &:Ts?
  end

  # Names of *Ts* transitions.
  # 
  def nTs ids=nil
    Ts_transitions( ids ).names
  end

  # *TS* transitions.
  # 
  def TS_transitions ids=nil
    return transitions.select &:TS? if ids.nil?
    transitions( ids ).aT_all "transition identifiers", "be TS", &:TS?
  end

  # Names of *TS* transitions.
  # 
  def nTS ids=nil
    TS_transitions( ids ).names
  end

  # *A* transitions.
  # 
  def A_transitions ids=nil
    return transitions.select &:A? if ids.nil?
    transitions( ids ).aT_all "transition identifiers", "be A", &:A?
  end

  # Names of *A* transitions.
  # 
  def nA ids=nil
    A_transitions( ids ).names
  end

  # *a* transitions.
  # 
  def a_transitions ids=nil
    return transitions.select &:a? if ids.nil?
    transitions( ids ).aT_all "transition identifiers",
                              "be a (non-assignment)", &:a?
  end

  # Names of *a* transitions.
  # 
  def na ids=nil
    A_transitions( ids ).names
  end

  # *S* transitions.
  # 
  def S_transitions ids=nil
    return transitions.select &:S? if ids.nil?
    transitions( ids ).aT_all "transition identifiers",
                              "be S (stoichiometric)", &:S?
  end

  # Names of *S* transitions.
  # 
  def nS ids=nil
    S_transitions( ids ).names
  end

  # *s* transitions.
  # 
  def s_transitions ids=nil
    return transitions.select &:s? if ids.nil?
    transitions( ids ).aT_all "transition identifiers",
                              "be s (non-stoichiometric)", &:s?
  end

  # Names of *s* transitions.
  # 
  def ns ids=nil
    s_transitions( ids ).names
  end

  # *T* transitions.
  #
  def T_transitions ids=nil
    return transitions.select &:T? if ids.nil?
    transitions( ids ).aT_all "transition identifiers",
                              "be T (timed)", &:T?
  end

  # Names of *T* transitions.
  # 
  def nT ids=nil
    T_transitions( ids ).names
  end

  # *t* transitions.
  # 
  def t_transitions ids=nil
    return transitions.select &:t? if ids.nil?
    transitions( ids ).aT_all "transition identifiers",
                              "be t (timeless)", &:t?
  end

  # Names of *t* transitions.
  # 
  def nt ids=nil
    t_transitions( ids ).names
  end  
end # class YPetri::Net::ElementAccess
