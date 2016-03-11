# encoding: utf-8

# Timeless simulator core. Knows thus far only one, but potentially several
# methods applicable to timeless systems simulations.
# 
class YPetri::Core::Timeless
  ★ YPetri::Core
  
  require_relative 'timeless/basic'
  
  METHODS = { basic: Basic } # basic PN execution
  # Note: the reason why Timeless core has distinct basic method is because
  # without having to consider timed transitions, it can be made simpler.

  # This inquirer (=Boolean selector) is always false for timeless cores.
  # 
  def timed?; false end

  # This inquirer (=Boolean selector) is always true for timeless cores.
  # 
  def timeless?; true end

  def initialize **named_args
    super
    extend METHODS.fetch simulation_method
  end
  
  # Computes the system state delta.
  # 
  def delta
    delta_timeless # this method was taken from core.rb
    # delta_ts + delta_tS # this is the contents of delta_timeless method
  end
  alias Δ delta
end # module YPetri::Core::Timeless
