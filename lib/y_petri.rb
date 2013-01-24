#encoding: utf-8

require 'gnuplot'
require 'csv'
require 'y_support/all'
require_relative 'y_petri/version'
require_relative 'y_petri/place'
require_relative 'y_petri/transition'
require_relative 'y_petri/net'
require_relative 'y_petri/simulation'
require_relative 'y_petri/timed_simulation'
require_relative 'y_petri/workspace'
require_relative 'y_petri/manipulator'

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
# 
module YPetri
  DEBUG = false

  DEFAULT_SIMULATION_SETTINGS = {
    step_size: 0.1,
    sampling_period: 5,
    target_time: 60
  }

  def self.included( receiver )      # :nodoc:
    receiver.instance_variable_set :@YPetriManipulator, Manipulator.new
    receiver.module_exec {
      define_method :y_petri_manipulator do
        self.class.instance_variable_get :@YPetriManipulator
      end

      # delegate( :workspace,
      #           :place, :transition,
      #           :p, :t,
      #           :places, :transitions, :nets,
      #           :simulations,
      #           :pp, :tt, :nn,
      #           :clamp_collections,
      #           :inital_marking_collections,
      #           :simulation_settings_collections,
      #           :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
      #           :Place,
      #           :Transition,
      #           :Net,
      #           :net_point_reset,
      #           :net_point_to, :net→,
      #           :net,
      #           :simulation_point_reset,
      #           :simulation_point_to,
      #           :simulation,
      #           :simulation_point_position,
      #           :cc_point_reset,
      #           :cc_point_to, :cc→,
      #           :clamp_collection, :cc,
      #           :cc_point_position,
      #           :imc_point_reset,
      #           :imc_point_to, :imc→,
      #           :initial_marking_collection, :imc,
      #           :imc_point_position,
      #           :ssc_point_reset,
      #           :ssc_point_to, :ssc→,
      #           :simulation_settings_collection, :ssc,
      #           :ssc_point_position,
      #           :net_selection,
      #           :simulation_selection,
      #           :ssc_selection,
      #           :cc_selection,
      #           :imc_selection,
      #           :net_selection_clear,
      #           :net_select!,
      #           :net_select,
      #           :net_unselect,
      #           :simulation_selection_clear,
      #           :simulation_select!,
      #           :simulation_select,
      #           :simulation_unselect,
      #           :cc_selection_clear,
      #           :cc_select!,
      #           :cc_select,
      #           :cc_unselect,
      #           :imc_selection_clear,
      #           :imc_select!,
      #           :imc_select,
      #           :imc_unselect,
      #           :ssc_selection_clear,
      #           :ssc_select!,
      #           :ssc_select,
      #           :ssc_unselect,
      #           :clamp,
      #           :initial_marking, :im,
      #           :set_step, :set_step_size,
      #           :set_time, :set_target_time,
      #           :set_sampling,
      #           :new_timed_simulation,
      #           :run!,
      #           :print_recording,
      #           :plot_recording,
      #           to: :y_petri_manipulator )
      
      [ :workspace,
        :place, :transition,
        :p, :t,
        :places, :transitions, :nets,
        :simulations,
        :pp, :tt, :nn,
        :clamp_collections,
        :inital_marking_collections,
        :simulation_settings_collections,
        :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
        :Place,
        :Transition,
        :Net,
        :net_point_reset,
        :net_point_to, :net→,
        :net,
        :simulation_point_reset,
        :simulation_point_to,
        :simulation,
        :simulation_point_position,
        :cc_point_reset,
        :cc_point_to, :cc→,
        :clamp_collection, :cc,
        :cc_point_position,
        :imc_point_reset,
        :imc_point_to, :imc→,
        :initial_marking_collection, :imc,
        :imc_point_position,
        :ssc_point_reset,
        :ssc_point_to, :ssc→,
        :simulation_settings_collection, :ssc,
        :ssc_point_position,
        :net_selection,
        :simulation_selection,
        :ssc_selection,
        :cc_selection,
        :imc_selection,
        :net_selection_clear,
        :net_select!,
        :net_select,
        :net_unselect,
        :simulation_selection_clear,
        :simulation_select!,
        :simulation_select,
        :simulation_unselect,
        :cc_selection_clear,
        :cc_select!,
        :cc_select,
        :cc_unselect,
        :imc_selection_clear,
        :imc_select!,
        :imc_select,
        :imc_unselect,
        :ssc_selection_clear,
        :ssc_select!,
        :ssc_select,
        :ssc_unselect,
        :clamp,
        :initial_marking, :im,
        :set_step, :set_step_size,
        :set_time, :set_target_time,
        :set_sampling,
        :new_timed_simulation,
        :run!,
        :print_recording,
        :plot_recording
      ].each do |ß|
        eval "def #{ß}( *aa, &b ); self.y_petri_manipulator.send #{ß}, *aa, &b end"
      end
    }
  end

  # delegate( :workspace,
  #           :place, :transition,
  #           :p, :t,
  #           :places, :transitions, :nets,
  #           :simulations,
  #           :pp, :tt, :nn,
  #           :clamp_collections,
  #           :inital_marking_collections,
  #           :simulation_settings_collections,
  #           :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
  #           :Place,
  #           :Transition,
  #           :Net,
  #           :net_point_reset,
  #           :net_point_to, :net→,
  #           :net,
  #           :simulation_point_reset,
  #           :simulation_point_to,
  #           :simulation,
  #           :simulation_point_position,
  #           :cc_point_reset,
  #           :cc_point_to, :cc→,
  #           :clamp_collection, :cc,
  #           :cc_point_position,
  #           :imc_point_reset,
  #           :imc_point_to, :imc→,
  #           :initial_marking_collection, :imc,
  #           :imc_point_position,
  #           :ssc_point_reset,
  #           :ssc_point_to, :ssc→,
  #           :simulation_settings_collection, :ssc,
  #           :ssc_point_position,
  #           :net_selection,
  #           :simulation_selection,
  #           :ssc_selection,
  #           :cc_selection,
  #           :imc_selection,
  #           :net_selection_clear,
  #           :net_select!,
  #           :net_select,
  #           :net_unselect,
  #           :simulation_selection_clear,
  #           :simulation_select!,
  #           :simulation_select,
  #           :simulation_unselect,
  #           :cc_selection_clear,
  #           :cc_select!,
  #           :cc_select,
  #           :cc_unselect,
  #           :imc_selection_clear,
  #           :imc_select!,
  #           :imc_select,
  #           :imc_unselect,
  #           :ssc_selection_clear,
  #           :ssc_select!,
  #           :ssc_select,
  #           :ssc_unselect,
  #           :clamp,
  #           :initial_marking, :im,
  #           :set_step, :set_step_size,
  #           :set_time, :set_target_time,
  #           :set_sampling,
  #           :new_timed_simulation,
  #           :run!,
  #           :print_recording,
  #           :plot_recording,
  #           to: :y_petri_manipulator )
end
