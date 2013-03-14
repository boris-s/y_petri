#encoding: utf-8

# === General assumptions.

Cell_diameter = Cell_∅ = 10.µm
Cytoplasm_volume = ( 4 / 3 * Math::PI * ( Cell_∅ / 2 ) ** 3 ).( SY::LitreVolume )

# Molecules per micromolar in average cell.
Pieces_per_µM = ( 1.µM * Cytoplasm_volume ).in( :unit )

# === Simulation settings

set_step 10.s.in( :s )
set_target_time 24.h.in( :s )      # up to 5 days is interesting
set_sampling 10.min.in( :s )
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step


