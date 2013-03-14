#encoding: utf-8

require 'y_petri'
include YPetri

require 'sy'
require 'mathn'

# === General assumptions

Cell_diameter = Cell_∅ = 10.µm
Cytoplasm_volume = ( 4 / 3 * Math::PI * ( Cell_∅ / 2 ) ** 3 ).( SY::LitreVolume )

# Molecules per micromolar in average cell.
Pieces_per_µM = ( 1.µM * Cytoplasm_volume ).in( :unit )

# === Simulation settings

set_step 10.s.in( :s )
set_target_time 24.h.in( :s )      # up to 5 days is interesting
set_sampling 10.min.in( :s )
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step

# # === Places (all in µM)

# ADP = Place m!: 137.0                    # Traut1994pcp
# ATP = Place m!: 2102.0                   # Traut1994pcp
# Thymidine = Place m!: 0.5                # Traut1994pcp
# TMP = Place m!: 0.0                      # in situ
# TDP = Place m!: 2.4                      # Traut1994pcp
# TTP = Place m!: 17.0                     # Traut1994pcp
# T23P = Place m!: TDP.default_marking + TTP.default_marking

# === Empirical places (in arbitrary units)

Timer = Place m!: 0
A_phase = Place m!: 0                    # in situ
S_phase = Place m!: 0                    # in situ
Cdc20A = Place m!: 1                     # in situ

# === Clock

Clock = Transition s: { Timer: 1 }, rate: 1

# === Empirical transitions

S_phase_duration = 12.h
S_phase_start = 5.h
S_phase_end = S_phase_start + S_phase_duration
A_phase_start = 3.h
A_phase_end = S_phase_end
Cdc20A_start = 22.h
Cdc20A_end = 1.h

# Figure them out as numbers in seconds.
Sα, Sω, Aα, Aω, Cdc20Aα, Cdc20Aω = [ S_phase_start, S_phase_end,
                                     A_phase_start, A_phase_end,
                                     Cdc20A_start, Cdc20A_end ].map &[ :in, :s ]

A_phase_ϝ = Transition assignment: true, domain: Timer, codomain: A_phase,
                       action: λ { |t| t > Aα && t < Aω ? 1 : 0 }
S_phase_ϝ = Transition assignment: true, domain: Timer, codomain: S_phase,
                       action: λ { |t| t > Sα && t < Sω ? 1 : 0 }
Cdc20A_ϝ = Transition assignment: true, domain: Timer, codomain: Cdc20A,
                      action: λ { |t| t < Cdc20Aω || t > Cdc20Aα ? 1 : 0 }

# # === Enzymes

# # ==== Thymidine kinase, cytoplasmic (TK1)

TK1_m = 24.8.kDa                     # Munchpetersen1995htk
TK1 = Place m!: 0.1                  # Total unphosphorylated TK1 monomer
TK1_4mer_Kd = 0.1                    # Dissoc. constant dimer >> tetramer
TK1di = Place m!: 0                  # TK1 dimer, unphosphorylated.
TK1di_P = Place m!: 0.1              # TK1 dimer, phosphorylated.
TK1tetra = Place m!: 0               # TK1 tetramer.

TK1tetra_ϝ = Transition assignment: true, domain: TK1, codomain: TK1tetra,
                        action: λ { |mono|
                                  r = mono / TK1_4mer_Kd
                                  TK1_4mer_Kd / 4 * ( r + 0.5 - ( r + 0.25 ) ** 0.5 )
                                } # root of a quadratic equation
TK1di_ϝ = Transition assignment: true, domain: [ TK1, TK1tetra ], codomain: TK1di,
                      action: λ { |mono, tetra| mono / 2 - tetra * 2 }

# TK1 synthesis
TK1_k_synth = 1.µM.h⁻¹.in "µM.s⁻¹"
TK1_synth = Transition domain: [ A_phase, S_phase ], s: { TK1: 1 },
                       Φ: λ { |a, s| TK1_k_synth * [ a - s, 0 ].max }

# TK1 phosphorylation
TK1_k_phosphoryl = ( 100.nM / 5.min / 500.nM ).in "s⁻¹"
TK1_phosphoryl = Transition domain: [ A_phase, TK1di ], s: { TK1: -2, TK1di_P: 1 },
                            Φ: λ { |a, tk1di| a > 0.5 ? 0 : tk1di * TK1_k_phosphoryl }

# TK1 degradation:
TK1_d_base = ( 10.nM.h⁻¹ / 1.µM ).in "s⁻¹"
TK1_d_Cdc20A = ( 100.nM / 10.min / 1.µM / 1 ).in "s⁻¹"
TK1_d_λ = lambda { |cdc, c| ( TK1_d_base + cdc * TK1_d_Cdc20A ) * c }
TK1_degrad = Transition domain: [ Cdc20A, TK1 ], s: { TK1: -1 }, Φ: TK1_d_λ
TK1di_P_degrad = Transition domain: [ Cdc20A, TK1di_P ], s: { TK1di_P: -1 }, Φ: TK1_d_λ

TK1_a = 9500.nmol.min⁻¹.mg⁻¹         # Munchpetersen1991dss; specific activity
TK1_kcat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹ # 3.93

# Reactants - dissociation (Michaelis) constants
TK1di_Kd_ATP = 4.7                       # Barroso2003tbd
TK1di_Kd_T = 15.0                       # Eriksson2002sfc
TK1tetra_Kd_T = 0.5                     # Munchpetersen1995htk
TK1di_Kd_TMP = TK1di_Kd_T
TK1tetra_Kd_TMP = TK1di_Kd_T

# Inhibitors
TK1di_Ki_TTP = 0.666

# Hill coefficients
TK1di_hill = 0.7                         # dimer, Eriksson2002sfc, Munchpetersen1995htk
TK1tetra_hill = 1                        # tetramer, Eriksson2002sfc

# # ==== Thymidine monophosphate kinase (TMPK)

# TMPK_m = 50.0.kDa
# TMPK = Place m!: 0.4 / 1_000_000
# TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹

# # Turnover number
# TMPK_kcat = ( TMPK_a * TMPK_m ).( SY::Amount / SY::Time ).in :s⁻¹ # 0.69

# # Michaelis constant (µM)
# TMPK_Kd_TMP = 40                    # Lee1977htk
# TMPK_Kd_TDP = TMPK_Kd_TMP

# # Inhibitors
# TMPK_Ki_TTP = 75

# # ==== DNA polymeration

# Genome_size = 3.gigaunit             # gigabases
# DNA_creation_speed = ( 2.0 * Genome_size / S_phase_duration ).in "unit.s⁻¹"
# TTP_use_rate = DNA_creation_speed / Pieces_per_µM

# # === Clamps (all in µM)

# clamp ADP: 6521.0, ATP: 3152.0, Thymidine: 0.5

# # === Function closures

# Vmax = λ { |enz_µM, kcat| enz_µM * kcat }

# # Reduced Michaelis constant.
# Km_reduced = λ { |km, hash_Ki=Hash.new|
#   km * hash_Ki.map { |inh_c, inh_Ki| inh_c / inh_Ki }.reduce( 1, :+ )
# }

# # Michaelis-Menten-Hill occupancy fraction.
# Occupancy = λ { |c, km, hill, hash_Ki=Hash.new|
#   if hill == 1 then c / ( c + Km_reduced.( km, hash_Ki ) ) else
#     c ** hill / ( c ** hill + Km_reduced.( km, hash_Ki ) ** hill )
#   end
# }

# # Michaelis-Menten-Hill equation with competitive inhibitors.
# MMi = λ { |c, km, hill, enz, kcat, hash_Ki=Hash.new|
#   Vmax.( enz, kcat ) * Occupancy.( c, km, hill, hash_Ki )
# }
 
# # === Pools

# TDP_ϝ = Transition assignment: true, domain: [ T23P, ADP, ATP ], codomain: TDP,
#                    action: lambda { |pool, di, tri| pool * di / ( di + tri ) }
# TTP_ϝ = Transition assignment: true, domain: [ T23P, ADP, ATP ], codomain: TTP,
#                    action: lambda { |pool, di, tri| pool * tri / ( di + tri ) }

# # === Enzyme reactions

# TMP_up_TK1di = Transition domain: [ Thymidine, TK1di, TTP, ADP, ATP ],
#                           stoichiometry: { Thymidine: -1, TMP: 1 },
#                           Φ: λ { |reactant, enz, inh, di, tri|
#                                MMi.( reactant, TK1di_Kd_T, TK1di_hill,
#                                enz, TK1_kcat * tri / ( di + tri ),
#                                inh => TK1di_Ki_TTP )
#                              }
# TMP_down_TK1di = Transition domain: [ TMP, TK1di, TTP, ADP, ATP ],
#                             stoichiometry: { TMP: -1, Thymidine: 1 },
#                             Φ: λ { |reactant, enz, inh, di, tri|
#                                  MMi.( reactant, TK1di_Kd_TMP, TK1di_hill,
#                                        enz, TK1_kcat * di / ( di + tri ),
#                                        inh => TK1di_Ki_TTP )
#                                }
# T_up_TK1di_P = Transition domain: [ Thymidine, TK1di_P, TTP, ADP, ATP ],
#                           stoichiometry: { Thymidine: -1, TMP: 1 },
#                           Φ: λ { |reactant, enz, inh, di, tri|
#                                MMi.( reactant, TK1di_Kd_T, TK1di_hill,
#                                      enz, TK1_kcat * tri / ( di + tri ),
#                                      inh => TK1di_Ki_TTP )
#                              }
# TMP_down_TK1di_P = Transition domain: [ TMP, TK1di, TTP, ADP, ATP ],
#                               stoichiometry: { TMP: -1, Thymidine: 1 },
#                               Φ: λ { |reactant, enz, inh, di, tri|
#                                    MMi.( reactant, TK1di_Kd_TMP, TK1di_hill,
#                                          enz, TK1_kcat * di / ( di + tri ),
#                                          inh => TK1di_Ki_TTP )
#                                  }
# T_up_TK1tetra = Transition domain: [ Thymidine, TK1tetra, TTP, ADP, ATP ],
#                            stoichiometry: { Thymidine: -1, TMP: 1 },
#                            Φ: λ { |reactant, enz, inh, di, tri|
#                                 MMi.( reactant, TK1tetra_Kd_T, TK1di_hill,
#                                       enz, TK1_kcat * tri / ( di + tri ),
#                                       inh => TK1di_Ki_TTP )
#                            }
# TMP_down_TK1tetra = Transition domain: [ TMP, TK1tetra, TTP, ADP, ATP ],
#                                stoichiometry: { TMP: -1, Thymidine: 1 },
#                                Φ: λ { |reactant, enz, inh, di, tri|
#                                     MMi.( reactant, TK1tetra_Kd_TMP, TK1di_hill,
#                                           enz, TK1_kcat * di / ( di + tri ),
#                                           inh => TK1di_Ki_TTP )
#                                   }

# TMP_up = Transition domain: [ TMP, TMPK, TTP, ADP, ATP ],
#                     stoichiometry: { TMP: -1, T23P: 1 },
#                     Φ: λ { |reactant, enz, inh, di, tri|
#                          MMi.( reactant, TMPK_Kd_TMP,
#                                enz, TMPK_kcat * tri / ( di + tri ), 1,
#                                inh => TMPK_Ki_TTP ) * 0.001
#                          0
#                        }
# TDP_down = Transition domain: [ TDP, TMPK, TTP, ADP, ATP ],
#                       stoichiometry: { T23P: -1, TMP: 1 },
#                       Φ: λ { |reactant, enz, inh, di, tri|
#                            MMi.( reactant, TMPK_Kd_TMP,
#                                  enz, TMPK_kcat * di / ( di + tri ), 1,
#                                  inh => TMPK_Ki_TTP ) * 0.001
#                            0
#                          }
# TTP_use = Transition domain: [ S_phase, TTP ], s: { T23P: -1 },
#                      Φ: λ { |s, ttp|
#                           if ttp < 5 then 0 else s > 0.5 ? TTP_use_rate : 0 end
#                           0
#                         }


# ==========================================================================
# === Model execution
# ==========================================================================

run!

# plot :all, except: Timer

# plot [ S_phase, TK1di, TK1tetra, TK1di_P, TMPK ]
plot [ S_phase, TK1, TK1di, TK1tetra, TK1di_P ]
plot :flux, except: Clock
# plot [ S_phase, Thymidine, TMP, TDP, TTP ]

# plot :state, except: [ Timer, AMP, ADP, ATP, UTP, UDP, UMP, GMP, DeoxyATP, DeoxyADP, DeoxyAMP,
#                        DeoxyCytidine, DeoxyCMP, DeoxyCDP, DeoxyCTP, DeoxyGTP, DeoxyGMP,
#                        DeoxyUridine, DeoxyUMP, DeoxyUDP, DeoxyUTP, DeoxyT23P ]
