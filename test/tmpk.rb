#encoding: utf-8

# Thymidine monophosphate kinase (TMPK)

TMPK_m = 50.0.kDa
TMPK = Place m!: 0.4

# TMPK synthesis is triggered when the cell cycle enters the "active phase".
# (Not done yet)

# TMPK degradation.
# (Not done yet)

# Specific activity of TMPK.

TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹        # Tamiya1989ctk

# And from it, the turnover number.

TMPK_kcat = ( TMPK_a * TMPK_m ).( SY::Amount / SY::Time ).in :s⁻¹ # 0.69

# Dissociation constants of the reactants (aka. Michaelis constants).

TMPK_Kd_TMP = 40                    # Lee1977htk
TMPK_Kd_TDP = TMPK_Kd_TMP

# Dissociation constants of the inhibitors (aka. inhibition constants).

# Inhibitors
TMPK_Ki_TTP = 10                     # product inhibition

# ===========================================================================
# REACTIONS

# TMPK TMP -> TDP

TMP_up = Transition domain: [ TMP, TMPK, TTP, ADP, ATP ],
                    stoichiometry: { TMP: -1, T23P: 1 },
                    rate: λ { |reactant, enz, inh, di, tri|
                            MMi.( reactant, TMPK_Kd_TMP,
                                  enz, TMPK_kcat * tri / ( di + tri ), 1,
                                  inh => TMPK_Ki_TTP )
                          }

# TMPK TDP -> TMP

TDP_down = Transition domain: [ TDP, TMPK, TTP, ADP, ATP ],
                      stoichiometry: { T23P: -1, TMP: 1 },
                      rate: λ { |reactant, enz, inh, di, tri|
                              MMi.( reactant, TMPK_Kd_TMP,
                                    enz, TMPK_kcat * di / ( di + tri ), 1,
                                    inh => TMPK_Ki_TTP )
                            }
