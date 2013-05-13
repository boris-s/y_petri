require 'gnuplot'
require 'csv'
require 'graphviz'

require 'y_support/local_object'
require 'y_support/respond_to'
require 'y_support/name_magic'
require 'y_support/unicode'
require 'y_support/typing'
require 'y_support/core_ext/hash'
require 'y_support/core_ext/array'
require 'y_support/stdlib_ext/matrix'
require 'y_support/abstract_algebra'
require 'y_support/kde'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/extract_options'

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
  DEFAULT_SIMULATION_SETTINGS = lambda do
    { step_size: 0.02,
      sampling_period: 2,
      target_time: 60 }
  end

  def self.included( receiver )
    # receiver.instance_variable_set :@YPetriManipulator, Manipulator.new
    # puts "included in #{receiver}"
    receiver.module_exec {
      define_method :y_petri_manipulator do
        singleton_class.instance_variable_get :@YPetriManipulator or
          ( puts "defining Manipulator for #{self} singleton class" if YPetri::DEBUG
            singleton_class.instance_variable_set :@YPetriManipulator, Manipulator.new )
      end
    }
  end

  delegate( :workspace, to: :y_petri_manipulator )

  # Petri net-related methods.
  delegate( :Place, :Transition, :Net,
            :place, :transition, :pl, :tr,
            :places, :transitions, :nets,
            :pp, :tt, :nn,
            :net_point,
            :net_selection,
            :net, :ne,
            :net_point_reset,
            :net_point_set,
            to: :y_petri_manipulator )

  # Simulation-related methods.
  delegate( :simulation_point, :ssc_point, :cc_point, :imc_point,
            :simulation_selection, :ssc_selection,
            :cc_selection, :imc_selection,
            :simulations,
            :clamp_collections,
            :initial_marking_collections,
            :simulation_settings_collections,
            :clamp_collection_names, :cc_names,
            :initial_marking_collection_names, :imc_names,
            :simulation_settings_collection_names, :ssc_names,
            :set_clamp_collection, :set_cc,
            :set_initial_marking_collection, :set_imc,
            :set_simulation_settings_collection, :set_ssc,
            :new_timed_simulation,
            :clamp_cc, :initial_marking_cc, :simulation_settings_cc,
            :simulation_point_position,
            :simulation,
            :clamp_collection, :cc,
            :initial_marking_collection, :imc,
            :simulation_settings_collection, :ssc,
            :clamp,
            :initial_marking,
            :set_step, :set_step_size
            :set_time, :set_target_time,
            :set_sampling,
            :set_simulation_method,
            :new_timed_simulation,
            :run!,
            :print_recording,
            :plot,
            :plot_selected,
            :plot_state,
            :plot_flux,
            to: :y_petri_manipulator )
end
