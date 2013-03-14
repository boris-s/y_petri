#! /usr/bin/ruby
#encoding: utf-8

require 'minitest/spec'
require 'minitest/autorun'
require 'mathn'
require 'sy'
require 'y_petri'
include YPetri

# include Pyper if require 'pyper'

require './general_assumptions.rb'
require './michaelis_menten.rb'

# === Simulation settings

set_step 10.s.in( :s )
set_target_time 24.h.in( :s )      # up to 5 days is interesting
set_sampling 10.min.in( :s )
set_simulation_method :Euler_with_timeless_transitions_firing_after_each_step

# === Clock
# 
Timer = Place m!: 0
Clock = Transition s: { Timer: 1 }, rate: 1   # a transition here


# === Empirical places (in arbitrary units)
# 
A_phase = Place m!: 0                    # in situ
S_phase = Place m!: 0                    # in situ
Cdc20A = Place m!: 1                     # in situ



# **************************************************************************
# Cell cycle test.
# **************************************************************************
#
require './cell_cycle.rb'
# run!
# plot [ S_phase, A_phase, Cdc20A ]


# === Chemical places (all in µM)

ADP = Place m!: 137.0                    # Traut1994pcp
ATP = Place m!: 2102.0                   # Traut1994pcp
Thymidine = Place m!: 0.5                # Traut1994pcp
TMP = Place m!: 0.0                      # in situ
TDP = Place m!: 2.4                      # Traut1994pcp
TTP = Place m!: 17.0                     # Traut1994pcp



# **************************************************************************
# Pools test.
# **************************************************************************
#
require './pools'
# run!
# plot [ TMP, TDP, TTP, T23P ]



# **************************************************************************
# DNA polymerase test.
# **************************************************************************
#
require './dna_polymerase'
set_sampling 30
# run!
# plot [ TMP, TDP, TTP, T23P ]
# plot_flux except: Clock

# Mocking
influx_T23P = 0.1
T23P_flux_clamp = Transition stoichiometry: { T23P: 1 },
                             rate: λ { influx_T23P }

# run!
# plot [ TMP, TDP, TTP, T23P ]
# plot_flux except: Clock


# **************************************************************************
# TMPK test.
# **************************************************************************
#
require './tmpk'

influx_T23P = 0

# run!
# plot [ TMP, TDP, TTP, T23P ]

# Another mocking.

influx_TMP = 0.2
TMP_flux_clamp = Transition stoichiometry: { TMP: 1 },
                            rate: λ { influx_TMP }

# run!
# plot [ TMP, TDP, TTP, T23P ]
# plot :flux, except: [ Clock, T23P_flux_clamp ]



# **************************************************************************
# TK1 Test.
# **************************************************************************
#
require './tk1'

influx_TMP = 0

set_step 2

influx_Thymidine = 0.25
Thymidine_flux_clamp = Transition stoichiometry: { Thymidine: 1 },
                                  rate: λ { influx_Thymidine }

# run!
# plot [ Thymidine, TMP, TDP, TTP, T23P ]
# plot :flux, except: [ Clock, T23P_flux_clamp, TMP_flux_clamp ]

# This barely fulfills the need

TK1_k_synth = 25.nM.min⁻¹.in "µM.s⁻¹"
TK1_kcat = TK1_kcat * 3

clamp Thymidine: 0.5
set_step 0.1

# run!
# plot [ Thymidine, TMP, TDP, TTP, T23P ]
# plot :flux, except: [ Clock, T23P_flux_clamp, TMP_flux_clamp, Thymidine_flux_clamp ]

#  But let' back out from it

TK1_k_synth = 1.µM.h⁻¹.in "µM.s⁻¹"
TK1_kcat = TK1_kcat / 3
set_step 5
set_sampling 5.min.in( :s )
TMPK_kcat = TMPK_kcat * 3

# And let's clamp Thymidine at 10.µM instead.

clamp Thymidine: 6

Phosphatase = Transition s: { T23P: -1, TMP: 1 },
                         rate: 0.05

Phosphatase_II = Transition s: { TMP: -1, Thymidine: 1 },
                            rate: 0.05
                         

run!
plot [ Thymidine, TMP, TDP, TTP, T23P ]
plot :flux, except: [ Clock, T23P_flux_clamp, TMP_flux_clamp, Thymidine_flux_clamp ]

