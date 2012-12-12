#encoding: utf-8

require 'gnuplot'
require 'csv'
require 'y_support'
require 'name_magic'
require 'y_petri/version'

include YSupport

# YPetri represents Petri net (PN) formalism.
#
# A PN consists of places and transitions. There are also arcs, that is,
# "arrows" connecting places and transitions, though arcs are not considered
# first class citizens in YPetri.
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

module YPetri
  require_relative 'y_petri/place'
  require_relative 'y_petri/transition'
  require_relative 'y_petri/net'
  require_relative 'y_petri/simulation'
  require_relative 'y_petri/timed_simulation'
  require_relative 'y_petri/workspace'
  require_relative 'y_petri/manipulator'

  DEFAULT_SIMULATION_SETTINGS = {
    step_size: 0.1,
    sampling_period: 5,
    target_time: 60
  }

  def self.included( receiver )      # :nodoc:
    receiver.instance_variable_set :@YPetriManipulator, Manipulator.new
  end

  delegate :workspace,
           :Place, :Transition, :Net,
           :place, :transition, :net, :simulation,
           :p, :t, :n,
           :places, :transitions, :nets, :simulations,
           :pp, :tt, :nn,
           :clamp_collections, :clamp_cc,
           :initial_marking_collections, :initial_marking_cc,
           :simulation_settings_collections, :simulation_settings_cc,
           :clamp_collection, :cc,
           :initial_marking_collection, :imc,
           :simulation_settings_collection, :ssc,
           :print_recording, :plot_recording,
           :clamp, :initial_marking, :im,
           :set_step, :set_step_size,
           :set_sampling,
           :set_time, :set_target_time,
           :new_timed_simulation,
           :run!, :plot_recording,
           to: :@YPetriManipulator
end
