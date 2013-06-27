# Selections of various kinds of places / transitions (place names / transition
# names) in a Petri net.
# 
class YPetri::Net
  # Names of places in the net.
  # 
  def pp
    places.map &:name
  end

  # Names of transitions in the net.
  # 
  def tt
    transitions.map &:name
  end

  # Array of _ts_ transitions in the net.
  # 
  def timeless_nonstoichiometric_transitions
    transitions.select { |t| t.timeless? && t.nonstoichiometric? }
  end
  alias ts_transitions timeless_nonstoichiometric_transitions

  # Names of _ts_ transitions in the net.
  # 
  def timeless_nonstoichiometric_tt
    timeless_nonstoichiometric_transitions.map &:name
  end
  alias ts_tt timeless_nonstoichiometric_tt

  # Array of _tsa_ transitions in the net.
  # 
  def timeless_nonstoichiometric_nonassignment_transitions
    transitions.select { |t|
      t.timeless? && t.nonstoichiometric? && ! t.assignment_action?
    }
  end
  alias tsa_transitions timeless_nonstoichiometric_nonassignment_transitions

  # Names of _tsa_ transitions in the net.
  # 
  def timeless_nonstoichiometric_nonassignment_tt
    timeless_nonstoichiometric_nonassignment_transitions.map &:name
  end
  alias tsa_tt timeless_nonstoichiometric_nonassignment_tt

  # Array of _tS_ transitions in the net.
  # 
  def timeless_stoichiometric_transitions
    transitions.select { |t| t.timeless? && t.stoichiometric? }
  end
  alias tS_transitions timeless_stoichiometric_transitions

  # Names of _tS_ transitions in the net.
  # 
  def timeless_stoichiometric_tt
    timeless_stoichiometric_transitions.map &:name
  end
  alias tS_tt timeless_stoichiometric_tt

  # Array of _Tsr_ transitions in the net.
  # 
  def timed_nonstoichiometric_transitions_without_rate
    transitions.select { |t| t.timed? && t.nonstoichiometric? && t.rateless? }
  end
  alias timed_rateless_nonstoichiometric_transitions \
        timed_nonstoichiometric_transitions_without_rate
  alias Tsr_transitions timed_nonstoichiometric_transitions_without_rate

  # Names of _Tsr_ transitions in the net.
  # 
  def timed_nonstoichiometric_tt_without_rate
    timed_nonstoichiometric_transitions_without_rate.map &:name
  end
  alias timed_rateless_nonstoichiometric_tt \
        timed_nonstoichiometric_tt_without_rate
  alias Tsr_tt timed_nonstoichiometric_tt_without_rate

  # Array of _TSr_ transitions in the net.
  # 
  def timed_stoichiometric_transitions_without_rate
    transitions.select { |t| t.timed? && t.stoichiometric? && t.rateless? }
  end
  alias timed_rateless_stoichiometric_transitions \
        timed_stoichiometric_transitions_without_rate
  alias TSr_transitions timed_stoichiometric_transitions_without_rate

  # Names of _TSr_ transitions in the net.
  # 
  def timed_stoichiometric_tt_without_rate
    timed_stoichiometric_transitions_without_rate.map &:name
  end
  alias timed_rateless_stoichiometric_tt timed_stoichiometric_tt_without_rate
  alias Tsr_tt timed_stoichiometric_tt_without_rate

  # Array of _sR_ transitions in the net.
  # 
  def nonstoichiometric_transitions_with_rate
    transitions.select { |t| t.has_rate? && t.nonstoichiometric? }
  end
  alias sR_transitions nonstoichiometric_transitions_with_rate

  # Names of _sR_ transitions in the net.
  # 
  def nonstoichiometric_tt_with_rate
    nonstoichiometric_transitions_with_rate.map &:name
  end
  alias sR_tt nonstoichiometric_tt_with_rate

  # Array of _SR_ transitions in the net.
  # 
  def stoichiometric_transitions_with_rate
    transitions.select { |t| t.has_rate? and t.stoichiometric? }
  end
  alias SR_transitions stoichiometric_transitions_with_rate

  # Names of _SR_ transitions in the net.
  # 
  def stoichiometric_tt_with_rate
    stoichiometric_transitions_with_rate.map &:name
  end
  alias SR_tt stoichiometric_tt_with_rate

  # Array of transitions with _explicit assignment action_ (_A transitions_)
  # in the net.
  # 
  def assignment_transitions
    transitions.select { |t| t.assignment_action? }
  end
  alias A_transitions assignment_transitions

  # Names of transitions with _explicit assignment action_ (_A transitions_)
  # in the net.
  # 
  def assignment_tt
    assignment_transitions.map &:name
  end
  alias A_tt assignment_tt

  # Array of _stoichiometric_ transitions in the net.
  # 
  def stoichiometric_transitions
    transitions.select &:stoichiometric?
  end
  alias S_transitions stoichiometric_transitions

  # Names of _stoichiometric_ transitions in the net.
  # 
  def stoichiometric_tt
    stoichiometric_transitions.map &:name
  end
  alias S_tt stoichiometric_tt

  # Array of _nonstoichiometric_ transitions in the net.
  # 
  def nonstoichiometric_transitions
    transitions.select &:nonstoichiometric?
  end
  alias s_transitions nonstoichiometric_transitions

  # Names of _nonstoichimetric_ transitions in the net.
  # 
  def nonstoichiometric_tt
    nonstoichiometric_transitions.map &:name
  end
  alias s_tt nonstoichiometric_tt

  # Array of _timed_ transitions in the net.
  #
  def timed_transitions; transitions.select &:timed? end
  alias T_transitions timed_transitions

  # Names of _timed_ transitions in the net.
  # 
  def timed_tt; timed_transitions.map &:name end
  alias T_tt timed_tt

  # Array of _timeless_ transitions in the net.
  # 
  def timeless_transitions; transitions.select &:timeless? end
  alias t_transitions timeless_transitions

  # Names of _timeless_ transitions in the net.
  # 
  def timeless_tt; timeless_transitions.map &:name end
  alias t_tt timeless_tt

  # Array of _transitions with rate_ in the net.
  # 
  def transitions_with_rate; transitions.select &:has_rate? end
  alias R_transitions transitions_with_rate

  # Names of _transitions with rate_ in the net.
  # 
  def tt_with_rate; transitions_with_rate.map &:name end
  alias R_tt tt_with_rate

  # Array of _rateless_ transitions in the net.
  # 
  def rateless_transitions; transitions.select &:rateless? end
  alias transitions_without_rate rateless_transitions
  alias r_transitions rateless_transitions

  # Names of _rateless_ transitions in the net.
  # 
  def rateless_tt; rateless_transitions.map &:name end
  alias tt_without_rate rateless_tt
  alias r_tt rateless_tt
end # class YPetri::Net
