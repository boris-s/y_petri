#encoding: utf-8

# Constants that control the cell cycle settings.

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

# Transitions with assignment action (A transitions) controlling the state
# of A_phase, S_phase and Cdc20A (aka. anaphase promoting complex, APC).

A_phase_ϝ = Transition assignment: true,
                       domain: Timer,
                       codomain: A_phase,
                       action: λ { |t| t > Aα && t < Aω ? 1 : 0 }

S_phase_ϝ = Transition assignment: true,
                       domain: Timer,
                       codomain: S_phase,
                       action: λ { |t| t > Sα && t < Sω ? 1 : 0 }

Cdc20A_ϝ = Transition assignment: true,
                      domain: Timer,
                      codomain: Cdc20A,
                      action: λ { |t| t < Cdc20Aω || t > Cdc20Aα ? 1 : 0 }
