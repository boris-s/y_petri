#encoding: utf-8

# Thymidine kinase 1 (cytoplasmic).

TK1_m = 24.8.kDa                     # Munchpetersen1995htk
TK1 = Place m!: 0.1                  # Total unphosphorylated TK1 monomer
TK1_4mer_Kd = 0.1                    # Dissoc. constant dimer >> tetramer
TK1di = Place m!: 0                  # TK1 dimer, unphosphorylated.
TK1di_P = Place m!: 0.1              # TK1 dimer, phosphorylated.
TK1tetra = Place m!: 0               # TK1 tetramer.

# Tetramer level is computed by an A transition from a quadratic equation.

TK1tetra_ϝ = Transition assignment: true,
                        domain: TK1,
                        codomain: TK1tetra,
                        action: λ { |mono|
                                  r = mono / TK1_4mer_Kd
                                  TK1_4mer_Kd / 4 * ( r + 0.5 - ( r + 0.25 ) ** 0.5 )
                                } # root of a quadratic equation

# Dimer level is calculated by subtraction (A transition again).

TK1di_ϝ = Transition assignment: true,
                     domain: [ TK1, TK1tetra ],
                     codomain: TK1di,
                     action: λ { |mono, tetra| mono / 2 - tetra * 2 }

# TK1 synthesis is triggered when the cell cycle enters the "active phase".

TK1_k_synth = 1.µM.h⁻¹.in "µM.s⁻¹"
TK1_synth = Transition domain: [ A_phase, S_phase ],
                       stoichiometry: { TK1: 1 },
                       rate: λ { |a, s| TK1_k_synth * [ a - s, 0 ].max }

# TK1 phosporylation is triggered outside the active phase.

TK1_k_phosphoryl = ( 100.nM / 5.min / 500.nM ).in "s⁻¹"
TK1_phosphoryl = Transition domain: [ A_phase, TK1di ],
                            stoichiometry: { TK1: -2, TK1di_P: 1 },
                            rate: λ { |a, tk1di|
                                    a > 0.5 ? 0 : tk1di * TK1_k_phosphoryl
                                  }

# TK1 degradation has 2 rates: base rate (always) and quick rate (when
# anaphase promoting complex is active).

TK1_d_base = ( 10.nM.h⁻¹ / 1.µM ).in "s⁻¹"
TK1_d_Cdc20A = ( 100.nM / 10.min / 1.µM / 1 ).in "s⁻¹"

# From these 2 rate constants, the rate of degradation is computed by this function:

TK1_d_λ = λ { |cdc, c| ( TK1_d_base + cdc * TK1_d_Cdc20A ) * c }

# TK1 degradation (an SR transition).

TK1_degrad = Transition domain: [ Cdc20A, TK1 ],
                        stoichiometry: { TK1: -1 },
                        rate: TK1_d_λ

# Phosphorylated TK1 degradation.

TK1di_P_degrad = Transition domain: [ Cdc20A, TK1di_P ],
                            stoichiometry: { TK1di_P: -1 },
                            rate: TK1_d_λ

# Specific activity of TK1.

TK1_a = 9500.nmol.min⁻¹.mg⁻¹         # Munchpetersen1991dss; specific activity

# And from it, turnover number.

TK1_kcat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹ # 3.93

# Dissociation constants of the reactants (aka. Michaelis constants).

TK1di_Kd_ATP = 4.7                   # Barroso2003tbd
TK1di_Kd_T = 15.0                    # Eriksson2002sfc
TK1tetra_Kd_T = 0.5                  # Munchpetersen1995htk
TK1di_Kd_TMP = TK1di_Kd_T
TK1tetra_Kd_TMP = TK1di_Kd_T

# Dissociation constants of the inhibitors (aka. inhibition constants).

TK1di_Ki_TTP = 0.666                 # product inhibition

# Hill coefficient.

TK1di_hill = 0.7                         # dimer, Eriksson2002sfc, Munchpetersen1995htk
TK1tetra_hill = 1                        # tetramer, Eriksson2002sf


# ===========================================================================
# REACTIONS

# Dimer Thymidine -> TMP

TMP_up_TK1di = Transition domain: [ Thymidine, TK1di, TTP, ADP, ATP ],
                          stoichiometry: { Thymidine: -1, TMP: 1 },
                          rate: λ { |reactant, enz, inh, di, tri|
                                  MMi.( reactant, TK1di_Kd_T, TK1di_hill,
                                        enz, TK1_kcat * tri / ( di + tri ),
                                        inh => TK1di_Ki_TTP )
                                }

# Dimer TMP -> Thymidine

TMP_down_TK1di = Transition domain: [ TMP, TK1di, TTP, ADP, ATP ],
                            stoichiometry: { TMP: -1, Thymidine: 1 },
                            rate: λ { |reactant, enz, inh, di, tri|
                                    MMi.( reactant, TK1di_Kd_TMP, TK1di_hill,
                                          enz, TK1_kcat * di / ( di + tri ),
                                          inh => TK1di_Ki_TTP )
                                  }

# Phosphorylated dimer Thymidine -> TMP

T_up_TK1di_P = Transition domain: [ Thymidine, TK1di_P, TTP, ADP, ATP ],
                          stoichiometry: { Thymidine: -1, TMP: 1 },
                          rate: λ { |reactant, enz, inh, di, tri|
                                  MMi.( reactant, TK1di_Kd_T, TK1di_hill,
                                        enz, TK1_kcat * tri / ( di + tri ),
                                        inh => TK1di_Ki_TTP )
                                }

# Phosphorylated dimer TMP -> Thymidine

TMP_down_TK1di_P = Transition domain: [ TMP, TK1di, TTP, ADP, ATP ],
                              stoichiometry: { TMP: -1, Thymidine: 1 },
                              rate: λ { |reactant, enz, inh, di, tri|
                                      MMi.( reactant, TK1di_Kd_TMP, TK1di_hill,
                                            enz, TK1_kcat * di / ( di + tri ),
                                            inh => TK1di_Ki_TTP )
                                    }

# Tetramer Thymidine -> TMP

T_up_TK1tetra = Transition domain: [ Thymidine, TK1tetra, TTP, ADP, ATP ],
                           stoichiometry: { Thymidine: -1, TMP: 1 },
                           rate: λ { |reactant, enz, inh, di, tri|
                                   MMi.( reactant, TK1tetra_Kd_T, TK1di_hill,
                                         enz, TK1_kcat * tri / ( di + tri ),
                                         inh => TK1di_Ki_TTP )
                                 }

# Tetramer TMP -> Thymidine

TMP_down_TK1tetra = Transition domain: [ TMP, TK1tetra, TTP, ADP, ATP ],
                               stoichiometry: { TMP: -1, Thymidine: 1 },
                               rate: λ { |reactant, enz, inh, di, tri|
                                       MMi.( reactant, TK1tetra_Kd_TMP, TK1di_hill,
                                             enz, TK1_kcat * di / ( di + tri ),
                                             inh => TK1di_Ki_TTP )
                                     }
