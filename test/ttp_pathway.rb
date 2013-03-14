#encoding: utf-8

# ==========================================================================
# Loading libraries
# ==========================================================================

require 'y_petri'
include YPetri
require 'sy'
require 'mathn'


# ==========================================================================
# Model setup
# ==========================================================================

require './general_assumptions.rb'
require './michaelis_menten.rb'


# === Simulation settings

set_step 5                           # seconds
set_target_time 24.h.in( :s )        # up to 5 days is interesting
set_sampling 5.min.in( :s )
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step


# === Clock

Timer = Place m!: 0
Clock = Transition s: { Timer: 1 }, rate: 1   # a transition here


# === Empirical places (in arbitrary units)

A_phase = Place m!: 0                    # in situ
S_phase = Place m!: 0                    # in situ
Cdc20A = Place m!: 1                     # in situ


# === Empirical transitions

require './cell_cycle.rb'


# === Chemical places (all in µM)

ADP = Place m!: 137.0                    # Traut1994pcp
ATP = Place m!: 2102.0                   # Traut1994pcp
Thymidine = Place m!: 0.5                # Traut1994pcp
TMP = Place m!: 0.0                      # in situ
TDP = Place m!: 2.4                      # Traut1994pcp
TTP = Place m!: 17.0                     # Traut1994pcp

require './pools' # instead of NDPK


# === Enzymes

require './tk1'
require './tmpk'
require './dna_polymerase'


# Futile cycles.

Phosphatase = Transition s: { T23P: -1, TMP: 1 },
                         rate: 0.05

Phosphatase_II = Transition s: { TMP: -1, Thymidine: 1 },
                            rate: 0.05

# Modification to increase Vmax of TMPK.

TMPK_kcat = TMPK_kcat * 3


# ==========================================================================
# Model execution
# ==========================================================================

# === Clamps (all in µM)

clamp Thymidine: 5


# === Make a new simulation and execute it.

run!


# === Make use of the results (just plotting for now).

# plot :all, except: Timer

# plot [ S_phase, TK1di, TK1tetra, TK1di_P, TMPK ]
# plot [ S_phase, TK1, TK1di, TK1tetra, TK1di_P ]

plot [ S_phase, Thymidine, TMP, TDP, TTP, T23P ]

plot :flux, except: Clock
# plot :flux, except: [ Clock, T23P_flux_clamp, TMP_flux_clamp, Thymidine_flux_clamp ]

# plot :state, except: [ Timer, AMP, ADP, ATP, UTP, UDP, UMP, GMP, DeoxyATP, DeoxyADP, DeoxyAMP,
#                        DeoxyCytidine, DeoxyCMP, DeoxyCDP, DeoxyCTP, DeoxyGTP, DeoxyGMP,
#                        DeoxyUridine, DeoxyUMP, DeoxyUDP, DeoxyUTP, DeoxyT23P ]
