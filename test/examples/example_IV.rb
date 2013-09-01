#encoding: utf-8

require 'y_petri' and include YPetri
# require 'mathn'

Pieces_per_microM = 100_000
set_step 10
set_sampling 30
set_target_time 30 * 60

# === Places (all in µM)

AMP = Place m!: 8695.0
ADP = Place m!: 6521.0
ATP = Place m!: 3152.0
DeoxyCytidine = Place m!: 5.0
DeoxyCTP = Place m!: 20.0
DeoxyGMP = Place m!: 20.0
UMP_UDP_pool = Place m!: 2737.0
DeoxyUMP_DeoxyUDP_pool = Place m!: 10.0
DeoxyTMP = Place m!: 50.0
DeoxyTDP_DeoxyTTP_pool = Place m!: 100.0
Thymidine = Place m!: 10.0

TK1 = Place m!: 100_000 / Pieces_per_microM
TYMS = Place m!: 100_000 / Pieces_per_microM
RNR = Place m!: 100_000 / Pieces_per_microM
TMPK = Place m!: 100_000 / Pieces_per_microM

# === Molecular masses

TK1_kDa = 24.8
TYMS_kDa = 66.0
RNR_kDa = 140.0
TMPK_kDa = 50.0

# === Enzyme specific activities

TK1_a = 5.40
TYMS_a = 3.80
RNR_a = 1.00
TMPK_a = 0.83

# === Clamps (all in µM)

clamp AMP: 8695.0, ADP: 6521.0, ATP: 3152.0
clamp DeoxyCytidine: 5.0, DeoxyCTP: 20.0, DeoxyGMP: 20.0
clamp Thymidine: 20
clamp UMP_UDP_pool: 2737.0

# === Function closures

Vmax_per_min_per_enz_molecule =
  lambda { |spec_act_microM_per_min_per_mg, kDa|
             spec_act_microM_per_min_per_mg * kDa }
Vmax_per_min =
  lambda { |spec_act, kDa, enz_molecules_per_cell|
           Vmax_per_min_per_enz_molecule.( spec_act, kDa ) *
             enz_molecules_per_cell }
Vmax_per_s =
  lambda { |spec_act, kDa, enz_mol_per_cell|
           Vmax_per_min.( spec_act, kDa, enz_mol_per_cell ) / 60 }
Km_reduced =
  lambda { |km, ki_hash={}|
           ki_hash.map { |c, ki| c / ki }.reduce( 1, :+ ) * km }
Occupancy =
  lambda { |c, km, compet_inh_w_Ki_hash={}|
           c / ( c + Km_reduced.( km, compet_inh_w_Ki_hash ) ) }
MM_with_inh_microM_per_second =
  lambda { |c, spec_act, kDa, enz_mol_per_cell, km, ki_hash={}|
            Vmax_per_s.( spec_act, kDa, enz_mol_per_cell ) *
              Occupancy.( c, km, ki_hash ) }
MMi = MM_with_inh_microM_per_second

# === Michaelis constants (all in µM)

TK1_Thymidine_Km = 5.0
TYMS_DeoxyUMP_Km = 2.0
RNR_UDP_Km = 1.0
DNA_creation_speed = 3_000_000_000.0 / ( 12 * 3600 ) / 4 / Pieces_per_microM
TMPK_DeoxyTMP_Km = 12.0

# === Transitions

Transition name: :TK1_Thymidine_DeoxyTMP,
           domain: [ Thymidine, TK1, DeoxyTDP_DeoxyTTP_pool, DeoxyCTP,
                     DeoxyCytidine, AMP, ADP, ATP ],
           stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
           rate: proc { |c, e, pool1, ci2, ci3, master1, master2, master3|
                        ci1 = pool1 * master3 / ( master2 + master3 )
                        MMi.( c, TK1_a, TK1_kDa, e, TK1_Thymidine_Km,
                              ci1 => 13.5, ci2 => 0.8, ci3 => 40.0 ) }

Transition name: :TYMS_DeoxyUMP_DeoxyTMP,
           domain: [ DeoxyUMP_DeoxyUDP_pool, TYMS, AMP, ADP, ATP ],
           stoichiometry: { DeoxyUMP_DeoxyUDP_pool: -1, DeoxyTMP: 1 },
           rate: proc { |pool, e, mono, di, tri|
                        c = pool * di / ( mono + di )
                        MMi.( c, TYMS_a, TYMS_kDa, e, TYMS_DeoxyUMP_Km ) }

Transition name: :RNR_UDP_DeoxyUDP,
           domain: [ UMP_UDP_pool, RNR, DeoxyUMP_DeoxyUDP_pool, AMP, ADP, ATP ],
           stoichiometry: { UMP_UDP_pool: -1, DeoxyUMP_DeoxyUDP_pool: 1 },
           rate: proc { |pool, e, mono, di, tri|
                        c = pool * di / ( mono + di )
                        MMi.( c, RNR_a, RNR_kDa, e, RNR_UDP_Km ) }

Transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
           stoichiometry: { DeoxyTDP_DeoxyTTP_pool: -1 },
           rate: proc { DNA_creation_speed / 4 }

Transition name: :TMPK_DeoxyTMP_DeoxyTDP,
           domain: [ DeoxyTMP, TMPK, DeoxyTDP_DeoxyTTP_pool, DeoxyGMP, AMP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, TMPK: 0, DeoxyTDP_DeoxyTTP_pool: 1 },
           rate: proc { |c, e, pool, ci4, mono, di, tri|
                        ci1 = di
                        ci2 = pool * di / ( di + tri )
                        ci3 = pool * tri / ( di + tri )
                        MMi.( c, TMPK_a, TMPK_kDa, e, TMPK_DeoxyTMP_Km,
                              ci1 => 250.0, ci2 => 30.0, ci3 => 750, ci4 => 117 ) }

Transition name: :PhosphataseI,
           stoichiometry: { DeoxyTMP: -1, Thymidine: 1 },
           rate: 0.04

Transition name: :PhosphataseII,
           stoichiometry: { DeoxyTDP_DeoxyTTP_pool: -1, DeoxyTMP: 1 },
           rate: 0.01

# === Transitions

net.visualize
run!
recording.plot
recording.flux.plot
