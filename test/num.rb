#encoding: utf-8

require 'y_petri'
include YPetri

require 'sy'
require 'mathn'

# ==========================================================================
# === General assumptions
# ==========================================================================

Cell_diameter = 10.µm
Cytoplasm_volume =
  ( 4 / 3 * Math::PI * ( Cell_diameter / 2 ) ** 3 ).( SY::LitreVolume )

# Molecules per micromolar in average cell.
Pieces_per_µM = ( 1.µM * Cytoplasm_volume ).in( :unit )

# ==========================================================================
# === Simulation settings
# ==========================================================================

set_step 60.s.in( :s )
set_target_time 24.h.in( :s )      # up to 5 days is interesting
set_sampling 10.min.in( :s )
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step

# ==========================================================================
# === Places (all in µM)
# ==========================================================================

AMP = Place m!: 82.0                     # Traut1994pcp
ADP = Place m!: 137.0                    # Traut1994pcp
ATP = Place m!: 2102.0                   # Traut1994pcp
UTP = Place m!: 253.0                    # Traut1994pcp
UDP = Place m!: ADP.m / ATP.m * UTP.m
UMP = Place m!: AMP.m / ATP.m * UTP.m
GMP = Place m!: 32.0                     # Traut1994pcp

DeoxyATP = Place m!: 2.4                 # Traut1994pcp
DeoxyADP = Place m!: ADP.m / ATP.m * DeoxyATP.m
DeoxyAMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

DeoxyCytidine = Place m!: 0.7            # Traut1994pcp
DeoxyCMP = Place m!: 1.9                 # Traut1994pcp
DeoxyCDP = Place m!: 0.1                 # Traut1994pcp
DeoxyCTP = Place m!: 4.5                 # Traut1994pcp

DeoxyGTP = Place m!: 2.7                 # Traut1994pcp
DeoxyGMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

DeoxyUridine = Place m!: 0.6             # Traut1994pcp
DeoxyUMP = Place m!: 2.70                # Traut1994pcp
DeoxyUDP = Place m!: 0.5                 # Traut1994pcp
DeoxyUTP = Place m!: 0.7                 # Traut1994pcp

Thymidine = Place m!: 0.5 # Traut1994pcp
DeoxyTMP = Place m!: 0.0                 # in situ
DeoxyTDP = Place m!: 2.4                 # Traut1994pcp
DeoxyTTP = Place m!: 17.0                # Traut1994pcp

DeoxyT23P = Place m!: DeoxyTDP.default_marking + DeoxyTTP.default_marking

# ==========================================================================
# === Empirical places (in arbitrary units)
# ==========================================================================

Timer = Place m!: 0
Clock = Transition s: { Timer: 1 }, rate: 1

A_phase = Place m!: 0                    # in situ
S_phase = Place m!: 0                    # in situ
Cdc20A = Place m!: 1                     # in situ

# ==========================================================================
# === Empirical transitions
# ==========================================================================

S_phase_duration = 12.h.in :s

A_phase_start = 3.h.in :s
S_phase_start = 5.h.in :s
S_phase_end = S_phase_start + S_phase_duration
A_phase_end = S_phase_end
Cdc20A_start = 22.h.in :s
Cdc20A_end = 15.min.in :s

Transition name: :A_phase_control,
           assignment: true,
           domain: Timer,
           codomain: A_phase,
           action: lambda { |t|
                     if t > A_phase_end then 0
                     elsif t > A_phase_start then 1
                     else 0 end
                   }

Transition name: :S_phase_control,
           assignment: true,
           domain: Timer,
           codomain: S_phase,
           action: lambda { |t|
                     if t > S_phase_end then 0
                     elsif t > S_phase_start then 1
                     else 0 end
                   }

Transition name: :Cdc20A,
           assignment: true,
           domain: Timer,
           codomain: Cdc20A,
           action: lambda { |t|
                     if t > Cdc20A_start then 1
                     elsif t > Cdc20A_end then 0
                     else 1 end
                   }

# ==========================================================================
# === Enzymes
# ==========================================================================

# --------------------------------------------------------------------------
# ==== Thymidine kinase, cytoplasmic (TK1)

# Molecular weight
TK1_m = 24.8.kDa                     # Munchpetersen1995htk

# Total unphosphorylated TK1 as monomer molarity.
TK1 = Place m!: 0

# Dissociation constant dimer >> tetramer assembly.
TK1_4mer_Kd = 0.1

# TK1 dimer, unphosphorylated. Can tetramerize.
TK1di = Place m!: 0

# TK1 dimer, phosphorylated. Phosphorylation prevents tetramerization.
TK1di_P = Place m!: 0

# TK1 tetramer.
TK1tetra = Place m!: 0

# Assignment transition that computes TK1_tetra.
Transition name: :TK1_tetra_ϝ,
           assignment: true,
           domain: TK1,              # total monomer, unphosphorylated dimer
           codomain: TK1tetra,       # tetramer
           action: lambda { |monomer| # from quad. eq. 2mer / 4mer balance
                     r = monomer / TK1_4mer_Kd
                     TK1_4mer_Kd / 4 * ( r + 0.5 - ( r + 0.25 ) ** 0.5 )
                   }

# Assignment transition that computes TK1_di from total TK1 monomer.
Transition name: :TK1_di_ϝ,
           assignment: true,
           domain: [ TK1, TK1tetra ],              # total TK1 monomer
           codomain: TK1di,          # TK1 unphosphorylated dimer
           action: lambda { |monomer, tetramer|
                     monomer / 2 - tetramer * 2
                   }

# Rate constant of TK1 synthesis:
TK1_k_synth = 1.µM.h⁻¹.in "µM.s⁻¹"

# TK1 synthesis:
Transition name: :TK1_synthesis,
           domain: [ A_phase, S_phase ],
           s: { TK1: 1 },
           rate: lambda { |a_phase, s_phase|
                   TK1_k_synth * [ a_phase - s_phase, 0 ].max
                 }

# Rate constant of TK1 phosphorylation:
TK1_k_phosphoryl = ( 100.nM / 5.min / 500.nM ).in "s⁻¹"

# TK1 phosphorylation:
Transition name: :TK1_phosphorylation,
           domain: [ A_phase, TK1di ],
           stoichiometry: { TK1: -1, TK1di_P: 1 },
           rate: lambda { |a_phase, tk1di|
                   if a_phase > 0.5 then 0 else tk1di * TK1_k_phosphoryl end
                 }

# Rate of TK1 degradation:
TK1_k_degrad_base = ( 10.nM.h⁻¹ / 1.µM ).in "s⁻¹"
TK1_k_degrad_Cdc20A = ( 100.nM / 10.min / 1.µM / 1 ).in "s⁻¹"

TK1_degrad_closure = lambda { |cdc, tk1| 
  ( TK1_k_degrad_base + cdc * TK1_k_degrad_Cdc20A ) * tk1
}

# TK1 degradation
TK1_degradation = Transition domain: [ Cdc20A, TK1 ],
                             s: { TK1: -1 },
                             rate: TK1_degrad_closure

# Phosphorylated TK1 degradation
TK1di_P_degradation = Transition domain: [ Cdc20A, TK1di_P ],
                                 s: { TK1di_P: -1 },
                                 rate: TK1_degrad_closure

# Specific activity
# TK1_a = 5.40.µmol.min⁻¹.mg⁻¹       # Sherley1988hct
TK1_a = 9500.nmol.min⁻¹.mg⁻¹         # Munchpetersen1991dss

# Turnover number of TK1 (dimer and tetramer have the same)
TK1_k_cat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹ # 3.93

# Reactants - dissociation (Michaelis) constants [µM].
TK1di_Kd_ATP = 4.7                       # Barroso2003tbd
TK1di_Kd_dT = 15.0                    # Eriksson2002sfc
TK1tetra_Kd_dT = TK1tetra_Kd_dTMP = 0.5  # Munchpetersen1995htk
TK1di_Kd_dTMP = TK1di_Kd_dT              # in situ
TK1tetra_Kd_dTMP = TK1di_Kd_dT           # in situ

# Competitive inhibitors - dissociation (inhibition) constants [µM].
# * dCTP is an inhibitor. (Cheng1978tkf)
# * dTTP, dCTP are both inhibitors of TK2. (Barroso2005kal)
# * The most authoritative original publication on kinetic properties of TK1
#   seems to be Lee1976hdk, if it is not the only one.

# It is known that mitochondrial enzyme is inhibited by 

# dTTP - strong feedback inhibition
TK1di_Ki_dTTP = 0.666                    # in situ

# Hill coefficient of TK1 dimer
TK1di_hill = 0.7                         # Eriksson2002sfc, Munchpetersen1995htk

# Hill coefficient of TK1 tetramer
TK1tetra_hill = 1                        # Eriksson2002sfc

# --------------------------------------------------------------------------
# ==== Thymidylate synthase (TYMS)

# Molecular mass
TYMS_m = 66.0.kDa

# TYMS
TYMS = Place m!: 0.4

# Specific activity
TYMS_a = 3.80.µmol.min⁻¹.mg⁻¹

# Turnover number
TYMS_k_cat = ( TYMS_a * TYMS_m ).( SY::Amount / SY::Time ).in :s⁻¹






TYMS_DeoxyUMP_Km = 2.0

# --------------------------------------------------------------------------
# ==== Ribonucleotide reductase (RNR)

# Molecular mass
RNR_m = 140.0.kDa

# Specific activity
RNR_a = 1.00.µmol.min⁻¹.mg⁻¹

# Turnover number
RNR_k_cat = ( RNR_a * RNR_m ).( SY::Amount / SY::Time ).in :s⁻¹







RNR_UDP_Km = 1.0

# --------------------------------------------------------------------------
# ==== Thymidine monophosphate kinase (TMPK)

# Enzyme molecular masses
TMPK_m = 50.0.kDa

# TMPK
TMPK = Place m!: 0.4

# Specific activity
TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹

# Turnover number
TMPK_k_cat = ( TMPK_a * TMPK_m ).( SY::Amount / SY::Time ).in :s⁻¹






TMPK_DeoxyTMP_Km = 12.0

# --------------------------------------------------------------------------
# === DNA polymeration

Genome_size = 3_000_000_000          # of bases
DNA_creation_speed = Genome_size / S_phase_duration # in base.s⁻¹



# ==========================================================================
# === Clamps (all in µM)
# ==========================================================================

clamp AMP: 8695.0, ADP: 6521.0, ATP: 3152.0
clamp DeoxyCytidine: 0.5, DeoxyCTP: 1.0, DeoxyGMP: 1.0
clamp Thymidine: 0.5




# ==========================================================================
# === Function closures
# ==========================================================================

# Enzyme Vmax closure.
# 
Vmax = lambda { |enzyme_µM, k_cat| enzyme_µM * k_cat }

# Michaelis constant reduced for competitive inhibitors.
# 
Km_reduced = -> reactant_Km, hash_Ki=Hash.new do
  hash_Ki.map { |compet_inhibitor_concentration, compet_inhibitor_Ki|
    compet_inhibitor_concentration / compet_inhibitor_Ki
  }.reduce( 1, :+ ) * reactant_Km
end

# Occupancy fraction of the Michaelis-Menten-Hill equation.
# 
Occupancy = -> reactant_µM, reactant_Km, k_hill, hash_Ki=Hash.new do
  reactant_µM ** k_hill /
    ( reactant_µM ** k_hill + Km_reduced.( reactant_Km, hash_Ki ) ** k_hill )
end

# Michaelis-Menten-Hill equation with competitive inhibitors.
# 
MMi = -> reactant_µM, reactant_Km, k_hill, enzyme_µM, k_cat, hash_Ki=Hash.new do
  Vmax.( enzyme_µM, k_cat ) *
    Occupancy.( reactant_µM, reactant_Km, k_hill, hash_Ki )
end



# ==========================================================================
# === Pools
# ==========================================================================

DeoxyTDP_maintenance = Transition assignment_action: true,
                                  domain: [ DeoxyT23P, ADP, ATP ],
                                  codomain: DeoxyTDP,
                                  action: lambda { |pool, adp, atp|
                                            pool * adp / ( adp + atp )
                                          }

DeoxyTTP_maintenance = Transition assignment_action: true,
                                  domain: [ DeoxyT23P, ADP, ATP ],
                                  codomain: DeoxyTTP,
                                  action: lambda { |pool, adp, atp|
                                            pool * atp / ( adp + atp )
                                          }

# ==========================================================================
# === Enzyme reactions
# ==========================================================================

Transition name: :TK1di_Thymidine_DeoxyTMP,
           domain: [ Thymidine, TK1di, DeoxyTTP, ADP, ATP ],
           stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             tri / ( di + tri ) * MMi.( reactant, TK1di_Kd_dT, TK1di_hill,
                                        enzyme, TK1_k_cat,
                                        inhibitor => TK1di_Ki_dTTP )
           }

Transition name: :TK1di_DeoxyTMP_Thymidine,
           domain: [ DeoxyTMP, TK1di, DeoxyTTP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, Thymidine: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             di / ( di + tri ) * MMi.( reactant, TK1di_Kd_dTMP, TK1di_hill,
                                       enzyme, TK1_k_cat,
                                       inhibitor => TK1di_Ki_dTTP )
           }

Transition name: :TK1di_P_Thymidine_DeoxyTMP,
           domain: [ Thymidine, TK1di_P, DeoxyTTP, ADP, ATP ],
           stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             tri / ( di + tri ) * MMi.( reactant, TK1di_Kd_dT, TK1di_hill,
                                        enzyme, TK1_k_cat,
                                        inhibitor => TK1di_Ki_dTTP )
           }

Transition name: :TK1di_P_DeoxyTMP_Thymidine,
           domain: [ DeoxyTMP, TK1di, DeoxyTTP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, Thymidine: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             di / ( di + tri ) * MMi.( reactant, TK1di_Kd_dTMP, TK1di_hill,
                                       enzyme, TK1_k_cat,
                                       inhibitor => TK1di_Ki_dTTP )
           }

Transition name: :TK1tetra_Thymidine_DeoxyTMP,
           domain: [ Thymidine, TK1di, DeoxyTTP, ADP, ATP ],
           stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             tri / ( di + tri ) * MMi.( reactant, TK1tetra_Kd_dT, TK1di_hill,
                                        enzyme, TK1_k_cat,
                                        inhibitor => TK1di_Ki_dTTP )
           }

Transition name: :TK1tetra_DeoxyTMP_Thymidine,
           domain: [ DeoxyTMP, TK1di, DeoxyTTP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, Thymidine: 1 },
           rate: proc { |reactant, enzyme, inhibitor, di, tri|
             di / ( di + tri ) * MMi.( reactant, TK1tetra_Kd_dTMP, TK1di_hill,
                                       enzyme, TK1_k_cat,
                                       inhibitor => TK1di_Ki_dTTP )
           }

# Transition name: :TYMS_DeoxyUMP_DeoxyTMP,
#            domain: [ DeoxyU12P, TYMS, AMP, ADP, ATP ],
#            stoichiometry: { DeoxyU12P: -1, DeoxyTMP: 1 },
#            rate: proc { |pool, enzyme, mono, di, tri|
#              reactant = pool * di / ( mono + di ) # conc. of DeoxyUMP
#              MMi.( reactant, TYMS_DeoxyUMP_Km, enzyme, TYMS_k_cat )
#            }

# Transition name: :RNR_UDP_DeoxyUDP,
#            domain: [ U12P, RNR, DeoxyU12P, AMP, ADP, ATP ],
#            stoichiometry: { U12P: -1, DeoxyU12P: 1 },
#            rate: proc { |pool, enzyme, mono, di, tri|
#              reactant = pool * di / ( mono + di )
#              MMi.( reactant, RNR_UDP_Km, enzyme, RNR_k_cat )
#            }

Transition name: :TMPK_DeoxyTMP_DeoxyTDP,
           domain: [ DeoxyTMP, TMPK, DeoxyTTP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, DeoxyT23P: 1 },
           rate: proc { |reactant, enzyme, pool, inhibitor, di, tri|
             tri / ( di + tri ) * MMi.( reactant, TMPK_Kd_dTMP,
                                        enzyme, TMPK_k_cat,
                                        inhibitor => TMPK_Ki_dTTP )
           }

Transition name: :TMPK_DeoxyTDP_DeoxyTMP,
           domain: [ DeoxyTDP, TMPK, DeoxyTTP, ADP, ATP ],
           stoichiometry: { DeoxyT23P: -1, DeoxyTMP: 1 },
           rate: proc { |reactant, enzyme, pool, inhibitor, di, tri|
             tri / ( di + tri ) * MMi.( reactant, TMPK_Kd_dTMP,
                                        enzyme, TMPK_k_cat,
                                        inhibitor => TMPK_Ki_dTTP )
           }


Transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
           stoichiometry: { DeoxyT23P: -1 },
           rate: proc { DNA_creation_speed / 4 }

# ==========================================================================
# === Model execution
# ==========================================================================

run!

# plot :all, except: Timer

plot S_phase

plot :state, except: [ Timer, AMP, ADP, ATP, UTP, UDP, UMP, GMP, DeoxyATP, DeoxyADP, DeoxyAMP,
                       DeoxyCytidine, DeoxyCMP, DeoxyCDP, DeoxyCTP, DeoxyGTP, DeoxyGMP,
                       DeoxyUridine, DeoxyUMP, DeoxyUDP, DeoxyUTP, DeoxyT23P ]

plot :flux, except: Clock
