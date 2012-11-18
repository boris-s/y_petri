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
require 'const_magic_ersatz'
require 'y_petri/version'

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
end
