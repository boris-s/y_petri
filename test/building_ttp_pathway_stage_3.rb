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

# === Enzymes

require './pools' # instead of NDPK
require './tk1'
require './tmpk'
require './ttp_use'

# ==========================================================================
# Model execution
# ==========================================================================

# === Clamps (all in µM)

clamp ADP: 6521.0, ATP: 3152.0, Thymidine: 0.5

# === Make a new simulation and execute it.

run!

# === Make use of the results (just plotting for now).

# plot :all, except: Timer

# plot [ S_phase, TK1di, TK1tetra, TK1di_P, TMPK ]
# plot [ S_phase, TK1, TK1di, TK1tetra, TK1di_P ]

plot [ S_phase, Thymidine, TMP, TDP, TTP ]

plot :flux, except: Clock

# plot :state, except: [ Timer, AMP, ADP, ATP, UTP, UDP, UMP, GMP, DeoxyATP, DeoxyADP, DeoxyAMP,
#                        DeoxyCytidine, DeoxyCMP, DeoxyCDP, DeoxyCTP, DeoxyGTP, DeoxyGMP,
#                        DeoxyUridine, DeoxyUMP, DeoxyUDP, DeoxyUTP, DeoxyT23P ]
