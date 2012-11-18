#encoding: utf-8

# YPetri represents Petri net (PN) formalism.
#
# A PN consists of places and transitions. There are also arcs, "arrows"
# connecting places and transitions, though arcs are not considered first
# class citizens in YPetri.
#
# At the time of PN execution (or simulation), transitions act upon places
# and change their marking by placing or removing tokens as dictated by
# their operation method ("function").
#
# Hybrid Functional Petri Net formalism, motivated by modeling cellular
# processes by their authors' Cell Illustrator software, explicitly
# introduces the possibility of both discrete and continuous places and
# transitions ('Hybrid'). YPetri does not emphasize this. Just like there is
# fluid transition between Fixnum and Bignum, there should be fluid
# transition between token amount representation as Integer (discrete) or
# Float (continuous) - the decision should be on the simulator.

require 'gnuplot'
require 'y_support'
require "y_petri/version"

module YPetri
  DEFAULT_SIMULATION_SETTINGS =
    { step_size: 1, sampling_period: 10, target_time: 60 }

  def self.included( receiver )
    $YPetriManipulatorInstance = ::YPetri::Manipulator.new
  end

  delegate :workspace,
           :places, :transitions, :nets, :simulations,
           :ccc, :imcc, :sscc,
           :pp, :tt, :nn,
           :print_recording, :plot_recording,
           :net, :simulation, :ssc, :cc, :imc,
           :place, :transition, :p, :t,
           :clamp, :initial_marking, :im,
           :set_step, :set_sampling, :set_time,
           :run!, :plot_recording, :new_timed_simulation,
           to: :$YPetriManipulatorInstance

  autoreq :place
  autoreq :transition
  autoreq :net

  autoreq :simulation
  autoreq :timed_simulation
  # autoreq :hybrid_timed_simulation # not yet, LATER

  autoreq :workspace
  autoreq :manipulator

  autoreq :const_magic_ersatz
  
  # Expects either a Place instance, or a name of an existing Place
  # instance. Place instance is returned unchanged, while if name was given,
  # correspondingly named instance is returned.
  def self.Place arg
    case arg
    when Place then return arg
    when String, Symbol then
      ( Place.instances.with_values( &:demodulize ).rassoc arg.to_s or
          raise AE, "Unknown place name: #{arg}" )[0]
    else raise AE, "Unexpected argument class: #{arg.class}" end
  end

  # Expects either a Transition instance, or a name of an existing
  # Transition instance. Transition instance is returned unchanged, while if
  # name was given, correspondingly named instance is returned.
  def self.Transition arg
    case arg
    when Transition then return arg
    when String, Symbol then
      ( Transition.instances.with_values( &:demodulize ).rassoc arg.to_s or
          raise AE, "Unknown place name: #{arg}" )[0]
    else raise AE, "Unexpected argument class: #{arg.class}" end
  end

  # Expects either a net instance, or a name of an existing net instance.
  # Net instance is returned unchanged, while if name was given,
  # correspondingly named instance is returned.
  def self.Net arg
    case arg
    when Net then return arg
    when String, Symbol then
      ( Net.instances.with_values( &:demodulize ).rassoc arg.to_s or
          raise AE, "Unknown place name: #{arg}" )[0]
    else raise AE, "Unexpected argument class: #{arg.class}" end
  end
end
