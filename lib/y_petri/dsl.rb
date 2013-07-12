# YPetri DSL.
# 
module YPetri
  module DSL
    def y_petri_manipulator
      @y_petri_manipulator ||= Manipulator.new
        .tap { puts "Defining Manipulator for #{self}" if YPetri::DEBUG }
  end

  delegate( :workspace, to: :y_petri_manipulator )

  # Petri net aspect.
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

  # Simulation aspect.
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
            :set_step, :set_step_size,
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
end
