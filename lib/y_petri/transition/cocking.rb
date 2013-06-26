# -*- coding: utf-8 -*-

# Cocking mechanics of a transition. A transition has to be cocked, before
# it can succesfuly +#fire+. (+#fire!+ method disregards cocking.)
# 
class YPetri::Transition
  # Is the transition cocked?
  # 
  def cocked?
    @cocked
  end

  # Negation of +#cocked?+ method.
  # 
  def uncocked?
    not cocked?
  end

  # Cocks teh transition -- allows +#fire+ to succeed.
  # 
  def cock
    @cocked = true
  end
  alias :cock! :cock

  # Sets the transition state to uncocked.
  # 
  def uncock
    @cocked = false
  end
  alias :uncock! :uncock
end # class YPetri::Transition
