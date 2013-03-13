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

# AMP = Place m!: 82.0                     # Traut1994pcp
# ADP = Place m!: 137.0                    # Traut1994pcp
# ATP = Place m!: 2102.0                   # Traut1994pcp
# UTP = Place m!: 253.0                    # Traut1994pcp
# UDP = Place m!: ADP.m / ATP.m * UTP.m
# UMP = Place m!: AMP.m / ATP.m * UTP.m
# GMP = Place m!: 32.0                     # Traut1994pcp

# DeoxyATP = Place m!: 2.4                 # Traut1994pcp
# DeoxyADP = Place m!: ADP.m / ATP.m * DeoxyATP.m
# DeoxyAMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

# DeoxyCytidine = Place m!: 0.7            # Traut1994pcp
# DeoxyCMP = Place m!: 1.9                 # Traut1994pcp
# DeoxyCDP = Place m!: 0.1                 # Traut1994pcp
# DeoxyCTP = Place m!: 4.5                 # Traut1994pcp

# DeoxyGTP = Place m!: 2.7                 # Traut1994pcp
# DeoxyGMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

# DeoxyUridine = Place m!: 0.6             # Traut1994pcp
# DeoxyUMP = Place m!: 2.70                # Traut1994pcp
# DeoxyUDP = Place m!: 0.5                 # Traut1994pcp
# DeoxyUTP = Place m!: 0.7                 # Traut1994pcp

# DeoxyThymidine = Place m!: 0.5           # Traut1994pcp
# DeoxyTMP = Place m!: 0.0                 # in situ
# DeoxyTDP = Place m!: 2.4                 # Traut1994pcp
# DeoxyTTP = Place m!: 17.0                # Traut1994pcp

# ==========================================================================
# === Empirical places (in arbitrary units)
# ==========================================================================

Timer = Place m!: 0
Transition name: :Clock,
           s: { Timer: 1 },
           rate: 1

A_phase = Place m!: 0                    # in situ
S_phase = Place m!: 0                    # in situ
Cdc20A = Place m!: 1                   # in situ

# ==========================================================================
# === Empirical transitions
# ==========================================================================

S_phase_duration = 12.h.in :s

A_phase_start = 3.h.in :s
S_phase_start = 5.h.in :s
S_phase_end = S_phase_start + S_phase_duration
A_phase_end = S_phase_end
Cdc20A_start = 23.h.in :s
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
TK1_m = 24.8.kDa

# Specific activity
TK1_a = 9500.mol.min⁻¹.mg⁻¹

# Total unphosphorylated TK1 as monomer molarity.
TK1 = Place m!: 0

# Dissociation constant dimer >> tetramer assembly.
TK1_4mer_Kd = 0.03

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
           stoichiometry: { TK1di: -1, TK1di_P: 1 },
           rate: lambda { |a_phase, reactant|
                   if a_phase then 0 else reactant * TK1_k_phosphoryl end
                 }

# Rate constant of TK1 degradation:
TK1_k_degrad_base = ( 10.nM.h⁻¹ / 1.µM ).in "s⁻¹"
TK1_k_degrad_Cdc20A = ( 100.nM / 10.min / 1.µM / 1 ).in "s⁻¹"

TK1_degrad_closure = lambda { |cdc, tk1| 
  ( TK1_k_degrad_base + cdc * TK1_k_degrad_Cdc20A ) * tk1
}

TK1_degradation = Transition domain: [ Cdc20A, TK1 ],
                             s: { TK1: -1 },
                             rate: TK1_degrad_closure
TK1di_P_degradation = Transition domain: [ Cdc20A, TK1di_P ],
                                 s: { TK1di_P: -1 },
                                 rate: TK1_degrad_closure

# Reactants - dissociation (Michaelis) constants [µM].
TK1di_Kd_ATP = 4.7                       # Barroso2003tbd
TK1di_Kd_dT = 15.0                       # Eriksson2002sfc

# Competitive inhibitors - dissociation (inhibition) constants [µM].
# * dCTP is an inhibitor. (Cheng1978tkf)
# * dTTP, dCTP are both inhibitors of TK2. (Barroso2005kal)
# * The most authoritative original publication on kinetic properties of TK1
#   seems to be Lee1976hdk, if it is not the only one.

# It is known that mitochondrial enzyme is inhibited by 

# dATP - strong feedback inhibition
TK1di_Ki_dTTP = 0.5

=begin

# Hill coefficient of TK1 dimer
TK1di_hill
# k_cat of TK1 dimer
TK1_k_cat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹
TK1_k_cat = 3.80


TYMS_m = 66.0.kDa
RNR_m = 140.0.kDa
TMPK_m = 50.0.kDa

# === Enzyme specific activities

TK1_a = 5.40.µmol.min⁻¹.mg⁻¹
TYMS_a = 3.80.µmol.min⁻¹.mg⁻¹
RNR_a = 1.00.µmol.min⁻¹.mg⁻¹
TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹

# === Enzyme kcat

TK1_k_cat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹
TYMS_k_cat = ( TYMS_a * TYMS_m ).( SY::Amount / SY::Time ).in :s⁻¹
RNR_k_cat = ( RNR_a * RNR_m ).( SY::Amount / SY::Time ).in :s⁻¹
TMPK_k_cat = ( TMPK_a * TMPK_m ).( SY::Amount / SY::Time ).in :s⁻¹

# === Clamps (all in µM)

clamp AMP: 8695.0, ADP: 6521.0, ATP: 3152.0
clamp DeoxyCytidine: 0.5, DeoxyCTP: 1.0, DeoxyGMP: 1.0
clamp Thymidine: 0.5
clamp U12P: 2737.0

# === Function closures

# Vmax of an enzyme.
# 
Vmax = -> enzyme_µM, k_cat do enzyme_µM * k_cat end

# Michaelis constant reduced for competitive inhibitors.
# 
Km_reduced = -> reactant_Km, hash_Ki=Hash.new do
  hash_Ki.map { |compet_inhibitor_concentration, compet_inhibitor_Ki|
    compet_inhibitor_concentration / compet_inhibitor_Ki
  }.reduce( 1, :+ ) * reactant_Km
end

# Occupancy fraction of the Michaelis-Menten equation.
# 
Occupancy = -> reactant_µM, reactant_Km, hash_Ki=Hash.new do
  reactant_µM / ( reactant_µM + Km_reduced.( reactant_Km, hash_Ki ) )
end

# Michaelis-Menten equation with competitive inhibitors.
# 
MMi = -> reactant_µM, reactant_Km, enzyme_µM, k_cat, hash_Ki=Hash.new do
  Vmax.( enzyme_µM, k_cat ) * Occupancy.( reactant_µM, reactant_Km, hash_Ki )
end

# === Michaelis constants (all in µM)

TK1_Thymidine_Km = 5.0
TYMS_DeoxyUMP_Km = 2.0
RNR_UDP_Km = 1.0
TMPK_DeoxyTMP_Km = 12.0

# === DNA synthesis speed

Genome_size = 3_000_000_000          # of bases
DNA_creation_speed = Genome_size / S_phase_duration.in( :s ) # in base.s⁻¹

# === Transitions

Transition name: :TK1_Thymidine_DeoxyTMP,
           domain: [ Thymidine, TK1, DeoxyT23P, DeoxyCTP, DeoxyCytidine, AMP, ADP, ATP ],
           stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
           rate: proc { |reactant, enzyme, pool, inhibitor_2, inhibitor_3, mono, di, tri|
             inhibitor_1 = pool * tri / ( di + tri ) # conc. of DeoxyTTP
             MMi.( reactant, TK1_Thymidine_Km, enzyme, TK1_k_cat,
                   inhibitor_1 => 13.5, inhibitor_2 => 0.8, inhibitor_3 => 40.0 )
           }

Transition name: :TYMS_DeoxyUMP_DeoxyTMP,
           domain: [ DeoxyU12P, TYMS, AMP, ADP, ATP ],
           stoichiometry: { DeoxyU12P: -1, DeoxyTMP: 1 },
           rate: proc { |pool, enzyme, mono, di, tri|
             reactant = pool * di / ( mono + di ) # conc. of DeoxyUMP
             MMi.( reactant, TYMS_DeoxyUMP_Km, enzyme, TYMS_k_cat )
           }

Transition name: :RNR_UDP_DeoxyUDP,
           domain: [ U12P, RNR, DeoxyU12P, AMP, ADP, ATP ],
           stoichiometry: { U12P: -1, DeoxyU12P: 1 },
           rate: proc { |pool, enzyme, mono, di, tri|
             reactant = pool * di / ( mono + di )
             MMi.( reactant, RNR_UDP_Km, enzyme, RNR_k_cat )
           }

Transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
           stoichiometry: { DeoxyT23P: -1 },
           rate: proc { DNA_creation_speed / 4 }

Transition name: :TMPK_DeoxyTMP_DeoxyTDP,
           domain: [ DeoxyTMP, TMPK, DeoxyT23P, DeoxyGMP, AMP, ADP, ATP ],
           stoichiometry: { DeoxyTMP: -1, DeoxyT23P: 1 },
           rate: proc { |reactant, enzyme, pool, inhibitor_4, mono, di, tri|
             inhibitor_1 = di
             inhibitor_2 = pool * di / ( di + tri ) # conc. of DeoxyTDP
             inhibitor_3 = pool * tri / ( di + tri ) # conc. of DeoxyTTP
             MMi.( reactant, TMPK_DeoxyTMP_Km, enzyme, TMPK_k_cat )
           }

=end

# # # execution
run!
plot except: Timer
