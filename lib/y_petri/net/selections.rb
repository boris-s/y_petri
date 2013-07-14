# Selections of various kinds of places / transitions (place names / transition
# names) in a Petri net.
# 
class YPetri::Net
  # Names of places in the net.
  # 
  def pn
    places.map &:name
  end

  # Names of transitions in the net.
  # 
  def tn
    transitions.map &:name
  end

  # *ts* transitions.
  # 
  def ts_transitions
    transitions.select &:ts?
  end

  # Names of *ts* transitions.
  # 
  def nts
    ts_transitions.names
  end

  # *tS* transitions.
  # 
  def tS_transitions
    transitions.select &:tS?
  end

  # Names of *tS* transitions.
  # 
  def ntS
    tS_transitions.names
  end

  # *Ts* transitions.
  # 
  def Ts_transitions
    transitions.select &:Ts?
  end

  # Names of *Ts* transitions.
  # 
  def nTs
    Ts_transitions().names
  end

  # *TS* transitions.
  # 
  def TS_transitions
    transitions.select &:TS?
  end

  # Names of *TS* transitions.
  # 
  def nTS
    TS_transitions().names
  end

  # *A* transitions.
  # 
  def A_transitions
    transitions.select &:A?
  end

  # Names of *A* transitions.
  # 
  def nA
    A_transitions().names
  end

  # *a* transitions.
  # 
  def a_transitions
    transitions.select &:a?
  end

  # Names of *a* transitions.
  # 
  def na
    A_transitions().names
  end

  # *S* transitions.
  # 
  def S_transitions
    transitions.select &:S?
  end

  # Names of *S* transitions.
  # 
  def nS
    S_transitions().names
  end

  # *s* transitions.
  # 
  def s_transitions
    transitions.select &:s?
  end

  # Names of *s* transitions.
  # 
  def ns
    s_transitions.names
  end

  # *T* transitions.
  #
  def T_transitions
    transitions.select &:T?
  end

  # Names of *T* transitions.
  # 
  def nT
    T_transitions().names
  end

  # *t* transitions.
  # 
  def t_transitions
    transitions.select &:t?
  end

  # Names of *t* transitions.
  # 
  def nt
    t_transitions.names
  end  
end # class YPetri::Net
