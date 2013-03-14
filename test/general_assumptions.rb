#encoding: utf-8

# === General assumptions.

Cell_diameter = Cell_∅ = 10.µm
Cytoplasm_volume = ( 4 / 3 * Math::PI * ( Cell_∅ / 2 ) ** 3 ).( SY::LitreVolume )

# Molecules per micromolar in average cell.
Pieces_per_µM = ( 1.µM * Cytoplasm_volume ).in( :unit )



