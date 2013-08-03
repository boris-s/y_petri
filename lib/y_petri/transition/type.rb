# encoding: utf-8

module YPetri::Transition::TypeInformation
  # Is this a timed stoichiometric transition?
  # 
  def TS?
    type == :TS
  end

  # Is this a timed non-stoichiometric transition?
  # 
  def Ts?
    type == :Ts
  end

  # Is this a timeless stoichiometric transition?
  # 
  def tS?
    type == :tS
  end

  # Is this a timeless non-stoichiometric transition?
  # 
  def ts?
    type == :ts
  end

  # Is this a stoichiometric transition?
  # 
  def stoichiometric?; @stoichiometric end
  alias S? stoichiometric?

  # Is this a non-stoichiometric transition?
  # 
  def nonstoichiometric?
    ! stoichiometric?
  end
  alias s? nonstoichiometric?

  # Does the transition's action depend on delta time?
  # 
  def timed?
    @timed
  end
  alias T? timed?

  # Is the transition timeless? (Opposite of #timed?)
  # 
  def timeless?
    not timed?
  end
  alias t? timeless?

  # Is the transition functional?
  # 
  # Explanation: If rate or action closure is supplied, a transition is always
  # considered 'functional'. Otherwise, it is considered not 'functional'.
  # Note that even transitions that are not functional still have standard
  # action acc. to Petri's definition. Also note that a timed transition is
  # necessarily functional.
  # 
  def functional?
    @functional
  end

  # Opposite of #functional?
  # 
  def functionless?
    not functional?
  end

  # Reports the transition's membership in one of the 4 basic types:
  # 
  # 1. TS .... timed stoichiometric
  # 2. tS .... timeless stoichiometric
  # 3. Ts .... timed nonstoichiometric
  # 4. ts .... timeless nonstoichiometric
  #
  # plus the fifth type
  #
  # 5. A .... assignment transitions
  # 
  def type
    return :A if assignment_action?
    timed? ? ( stoichiometric? ? :TS : :Ts ) : ( stoichiometric? ? :tS : :ts )
  end

  # Is this a transition with assignment action? (Transitions with assignment
  # action, or "assignment transitions", completely replace the marking of their
  # codomain with their action closure result, like in spreadsheets.)
  # 
  def assignment_action?
    @assignment_action
  end
  alias assignment? assignment_action?
  alias A? assignment_action?

  # Is this a non-assignment transition? (Opposite of +#A?+)
  # 
  def a?
    ! assignment_action?
  end
end # class YPetri::Transition::Type
