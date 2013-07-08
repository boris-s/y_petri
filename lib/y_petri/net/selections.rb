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
  def names_of_ts
    ts_transitions.names
  end
  alias n_ts names_of_ts

  # *tS* transitions.
  # 
  def tS_transitions
    transitions.select &:tS?
  end

  # Names of *tS* transitions.
  # 
  def names_of_tS
    tS_transitions.names
  end
  alias n_tS names_of_tS

  # *Ts* transitions.
  # 
  def Ts_transitions
    transitions.select &:Ts?
  end

  # Names of *Ts* transitions.
  # 
  def names_of_Ts
    Ts_transitions().names
  end
  alias n_Ts names_of_Ts

  # *TS* transitions.
  # 
  def TS_transitions
    transitions.select &:TS?
  end

  # Names of *TS* transitions.
  # 
  def names_of_TS
    TS_transitions().names
  end
  alias n_TS names_of_TS

  # *A* transitions.
  # 
  def A_transitions
    transitions.select &:A?
  end

  # Names of *A* transitions.
  # 
  def names_of_A
    A_transitions().names
  end
  alias n_A names_of_A

  # *a* transitions.
  # 
  def a_transitions
    transitions.select &:a?
  end

  # Names of *a* transitions.
  # 
  def names_of_a
    A_transitions().names
  end
  alias n_a names_of_a

  # *S* transitions.
  # 
  def S_transitions
    transitions.select &:S?
  end

  # Names of *S* transitions.
  # 
  def names_of_S
    S_transitions().names
  end
  alias n_S names_of_S

  # *s* transitions.
  # 
  def s_transitions
    transitions.select &:s?
  end

  # Names of *s* transitions.
  # 
  def names_of_s
    s_transitions.names
  end
  alias n_s names_of_s

  # *T* transitions.
  #
  def T_transitions
    transitions.select &:T?
  end

  # Names of *T* transitions.
  # 
  def names_of_T
    T_transitions().names
  end
  alias n_T names_of_T

  # *t* transitions.
  # 
  def t_transitions
    transitions.select &:t?
  end

  # Names of *t* transitions.
  # 
  def names_of_t
    t_transitions.names
  end  
  alias n_t names_of_t
end # class YPetri::Net
