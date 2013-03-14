#encoding: utf-8

# dTTP use by DNA polymeration

Genome_size = 3.gigaunit             # gigabases
DNA_creation_speed = ( 2.0 * Genome_size / S_phase_duration ).in "unit.s⁻¹"
TTP_use_rate = DNA_creation_speed / Pieces_per_µM


TTP_use = Transition domain: [ S_phase, TTP ], s: { T23P: -1 },
                     Φ: λ { |s, ttp|
                          if ttp < 5 then 0 else s > 0.5 ? TTP_use_rate : 0 end
                        }

