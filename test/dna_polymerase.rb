#encoding: utf-8

# TTP use by DNA polymeration

# === Constants

# Size of human genome.
# 
Genome_size = 3.gigaunit             # 3 gigabases

# During S phase, there is more or less stable speed of DNA replication
# and consequently, a stable average rate of demand for deoxynucleotides
# by the open replication forks.
# 
DNA_creation_speed =
  ( 2.0 * Genome_size / S_phase_duration )
  .in "unit.s⁻¹"

# From the number of bases, we can calculate the negtive contribution of
# the DNA polymerisation to the change of molarity of TTP.
# 
TTP_use_rate = DNA_creation_speed / Pieces_per_µM


# === Transition

TTP_use = Transition domain: [ S_phase, TTP ], s: { T23P: -1 },
                     rate: λ { |s, ttp|
                             # First, an absolute stop to the polymerase
                             # activity when the TTP pool falls near 0.
                             return 0 if ttp < 3
                             # Then, if there is enough TTP, and S_phase
                             # is on (marking 1 instead of 0), consume.
                             s > 0.5 ? TTP_use_rate : 0
                           }

