# encoding: utf-8

require_relative 'T'
require_relative 't'
require_relative 'A'

module YPetri::Transition::Types
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

  # Is this a timeless non-stoichiometric transition?
  # 
  def ts?
    type == :ts
  end
  alias B? ts?

  # Is this a timeless stoichiometric transition?
  # 
  def tS?
    type == :tS
  end
  alias C? tS?

  # Is this a timed non-stoichiometric transition?
  # 
  def Ts?
    type == :Ts
  end
  alias D? Ts?

  # Is this a timed stoichiometric transition?
  # 
  def TS?
    type == :TS
  end
  alias E? TS?

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

  # Does the transition's action depend on delta time? (Note that although A
  # transitions are technically timeless, for pragmatic reasons, they are
  # excluded from T/t classification, because they are generally handled
  # differently in Petri net execution.)
  # 
  def timed?
    return nil if A?
    @timed
  end
  alias T? timed?

  # Is the transition timeless? (Opposite of #timed?)
  # 
  def timeless?
    return nil if A?
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

  # Reports the transition's membership in one of the 5 basic types
  # using one-letter abbreviation:
  #
  # 1. A .... assignment
  # 2. B .... timeless nonstoichiometric (ts)
  # 3. C .... timeless stoichiometric (tS)
  # 4. D .... timed nonstoichiometric (Ts)
  # 5. E .... timed stoichiometric (TS)
  #
  def t
    return :A if assignment_action?
    timed? ? ( stoichiometric? ? :E : :D ) : ( stoichiometric? ? :C : :B )
  end

  # Reports the transition's membership in one of the 5 basic types
  # using two-letter abbreviation + A for assignment transition.
  # This methods reflects the fact that the new users may take time
  # to memorize the meaning of A, B, C, D, E transition types.
  # Two-letter abbreviations may be easier to figure out.
  #
  # 1. A .... assignment transitions (A-type)
  # 2. ts .... timeless nonstoichiometric (B-type)
  # 3. tS .... timeless stoichiometric (C-type)
  # 4. Ts .... timed nonstoichiometric (D-type)
  # 5. TS .... timed stoichiometric (E-type)
  # 
  def type
    { A: :A, B: :ts, C: :tS, D: :Ts, E: :TS }[ t ]
  end

  # Reports the transition's membership in one of the 5 basic types
  # as a full string.
  #
  # 1. assignment (A-type)
  # 2. timeless nonstoichiometric (B-type)
  # 3. timeless stoichiometric (C-type)
  # 4. timed nonstoichiometric (D-type)
  # 5. timed stoichiometric (E-type)
  #
  def type_full
    { A: "assignment",
      ts: "timeless nonstoichiometric",
      tS: "timeless stoichiometric",
      Ts: "timed nonstoichiometric",
      TS: "timed stoichiometric" }[ type ]
  end
end # class YPetri::Transition::Types
