#encoding: utf-8

require 'y_petri'
include YPetri
require 'sy'
require 'mathn'

# === General assumptions

Cell_diameter = 10.µm
Cytoplasm_volume = ( 4 / 3 * Math::PI * ( Cell_diameter / 2 ) ** 3 ).( SY::LitreVolume )
# Cytoplasm_volume = 5.0e-11.l         # of an average cell
# How many molecules are there in the average cell per micromolar.
Pieces_per_µM = ( 1.µM * Cytoplasm_volume ).in( :unit )

# === Simulation settings

set_step 60.s.in( :s )
set_target_time 20.min.in( :s )      # up to 5 days is interesting
set_sampling 120.s.in( :s )

# === Places (all in µM)

AMP = Place m!: 82.0                     # traut1994pcp
ADP = Place m!: 137.0                    # traut1994pcp
ATP = Place m!: 2102.0                   # traut1994pcp
UTP = Place m!: 253.0                    # traut1994pcp
UDP = Place m!: ADP.m / ATP.m * UTP.m
UMP = Place m!: AMP.m / ATP.m * UTP.m
GMP = Place m!: 32.0                     # traut1994pcp

DeoxyATP = Place m!: 2.4                 # traut1994pcp
DeoxyADP = Place m!: ADP.m / ATP.m * DeoxyATP.m
DeoxyAMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

DeoxyCytidine = Place m!: 0.7            # traut1994pcp
DeoxyCMP = Place m!: 1.9                 # traut1994pcp
DeoxyCDP = Place m!: 0.1                 # traut1994pcp
DeoxyCTP = Place m!: 4.5                 # traut1994pcp

DeoxyGTP = Place m!: 2.7                 # traut1994pcp
DeoxyGMP = Place m!: AMP.m / ATP.m * DeoxyATP.m

DeoxyUridine = Place m!: 0.6             # traut1994pcp
DeoxyUMP = Place m!: 2.70                # traut1994pcp
DeoxyUDP = Place m!: 0.5                 # traut1994pcp
DeoxyUTP = Place m!: 0.7                 # traut1994pcp

DeoxyThymidine = Place m!: 0.5           # traut1994pcp
DeoxyTMP = Place m!: 0.0                 # in situ
DeoxyTDP = Place m!: 2.4                 # traut1994pcp
DeoxyTTP = Place m!: 17.0                # traut1994pcp

# === Empirical places (in arbitrary units)

A_phase = Place m!: 1                    # in situ
S_phase = Place m!: 1                    # in situ
Cdc20A = Place m!: 0.0                   # in situ

# === Enzymes

# ==== Thymidine kinase, cytoplasmic (TK1)

# Molecular weight:
TK1_m = 24.8.kDa
TK1_a = 9500.mol.min⁻¹.mg⁻¹

TK1 = Place m!: 0                        # in situ; total unphosphorylated TK1
TK1_4mer_Kd = 0.03                       # in situ
TK1di = Place m!: 0                      # TK1 in the dimer form, unphosphorylated
TK1di_P = Place m!: 0                    # in situ; TK1 in the dimer form, phosphorylated
TK1tetra = Place m!: 0                   # TK1 in the tetramer form (phosphorylation prevents 4merization)

# Assignment transition keeping TK1_di level based on total TK1 monomer
Transition name: :TK1_di_ϝ,
           assignment: true,
           domain: TK1,
           codomain: TK1di,
           action: lambda { |monomer|    # solution of a quadratic equation for dimer / tetramer balance
                     TK1_4mer_Kd / 4 * ( ( 1 + 4 / TK1_4mer_Kd * monomer ) ** 0.5 - 1 )
                   }

# Assignment transition keeping TK1_tetra level based on total TK1 tetramer
Transition name: :TK1_tetra_ϝ,
           assignment: true,
           domain: [ TK1, TK1di ],
           codomain: TK1tetra,
           action: lambda { |monomer, dimer| monomer / 4 - dimer / 2 } # subtraction

# Dissociation constants [µM]

TK1di_Kd_ATP = 4.7                       # barroso2003tbd
TK1di_Kd_dT = 15.0                       # eriksson2002sfc

# FIXME - THIS IS HOW FAR I CAME

# Inhibition constant of dTTP
TK1di_Kd_dTTP
# Hill coefficient of TK1 dimer
TK1di_hill
# k_cat of TK1 dimer
TK1_k_cat = ( TK1_a * TK1_m ).( SY::Amount / SY::Time ).in :s⁻¹
TK1_k_cat = 3.80                        # 


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

S_phase_duration = 12.h
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

# execution
run!
plot_recording
