#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "Use of TimedSimulation with units" do
  before do
    require 'sy'

    @m = YPetri::Agent.new

    # === General assumptions
    Cytoplasm_volume = 5.0e-11.l
    Pieces_per_concentration = SY::Nᴀ * Cytoplasm_volume

    # === Simulation settings
    @m.set_step 60.s
    @m.set_target_time 10.min
    @m.set_sampling 120.s

    # === Places
    AMP = @m.Place m!: 8695.0.µM
    ADP = @m.Place m!: 6521.0.µM
    ATP = @m.Place m!: 3152.0.µM
    Deoxycytidine = @m.Place m!: 0.5.µM
    DeoxyCTP = @m.Place m!: 1.0.µM
    DeoxyGMP = @m.Place m!: 1.0.µM
    U12P = @m.Place m!: 2737.0.µM
    DeoxyU12P = @m.Place m!: 0.0.µM
    DeoxyTMP = @m.Place m!: 3.3.µM
    DeoxyT23P = @m.Place m!: 5.0.µM
    Thymidine = @m.Place m!: 0.5.µM
    TK1 = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
    TYMS = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
    RNR = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume
    TMPK = @m.Place m!: 100_000.unit.( SY::MoleAmount ) / Cytoplasm_volume

    # === Enzyme molecular masses
    TK1_m = 24.8.kDa
    TYMS_m = 66.0.kDa
    RNR_m = 140.0.kDa
    TMPK_m = 50.0.kDa

    # === Specific activities of the enzymes
    TK1_a = 5.40.µmol.min⁻¹.mg⁻¹
    TYMS_a = 3.80.µmol.min⁻¹.mg⁻¹
    RNR_a = 1.00.µmol.min⁻¹.mg⁻¹
    TMPK_a = 0.83.µmol.min⁻¹.mg⁻¹

    # === Clamps
    @m.clamp AMP: 8695.0.µM, ADP: 6521.0.µM, ATP: 3152.0.µM
    @m.clamp Deoxycytidine: 0.5.µM, DeoxyCTP: 1.0.µM, DeoxyGMP: 1.0.µM
    @m.clamp Thymidine: 0.5.µM
    @m.clamp U12P: 2737.0.µM

    # === Function closures

    # Vmax of an enzyme.
    # 
    Vmax_enzyme = lambda { |specific_activity, mass, enzyme_conc|
      specific_activity * mass * enzyme_conc.( SY::Molecularity )
    }

    # Michaelis constant reduced for competitive inhibitors.
    # 
    Km_reduced = lambda { |km, ki_hash={}|
      ki_hash.map { |concentration, ci_Ki|
        concentration / ci_Ki }
        .reduce( 1, :+ ) * km
    }

    # Occupancy of enzyme active sites at given concentration of reactants
    # and competitive inhibitors.
    # 
    Occupancy = lambda { |ʀ_conc, ʀ_Km, cɪ_Kɪ={}|
      ʀ_conc / ( ʀ_conc + Km_reduced.( ʀ_Km, cɪ_Kɪ ) )
    }

    # Michaelis and Menten equation with competitive inhibitors.
    # 
    MMi = MM_equation_with_inhibitors = lambda {
      |ʀ_conc, ᴇ_specific_activity, ᴇ_mass, ᴇ_conc, ʀ_Km, cɪ_Kɪ={}|
      Vmax_enzyme.( ᴇ_specific_activity, ᴇ_mass, ᴇ_conc ) *
        Occupancy.( ʀ_conc, ʀ_Km, cɪ_Kɪ )
    }

    # === Michaelis constants of the enzymes involved.

    TK1_Thymidine_Km = 5.0.µM
    TYMS_DeoxyUMP_Km = 2.0.µM
    RNR_UDP_Km = 1.0.µM
    TMPK_DeoxyTMP_Km = 12.0.µM

    # === DNA synthesis speed.

    DNA_creation_speed = 3_000_000_000.unit.( SY::MoleAmount ) / 12.h / Cytoplasm_volume

    # === Transitions

    # Synthesis of TMP by TK1.
    # 
    TK1_Thymidine_DeoxyTMP = @m.Transition s: { Thymidine: -1, DeoxyTMP: 1 },
      domain: [ Thymidine, TK1, DeoxyT23P, DeoxyCTP, Deoxycytidine, AMP, ADP, ATP ],
        rate: proc { |rc, e, pool1, ci2, ci3, master1, master2, master3|
                ci1 = pool1 * master3 / ( master2 + master3 )
                MMi.( rc, TK1_a, TK1_m, e, TK1_Thymidine_Km,
                      ci1 => 13.5.µM, ci2 => 0.8.µM, ci3 => 40.0.µM )
              }

    # Methylation of DeoxyUMP into TMP by TYMS.
    TYMS_DeoxyUMP_DeoxyTMP = @m.Transition s: { DeoxyU12P: -1, DeoxyTMP: 1 },
      domain: [ DeoxyU12P, TYMS, AMP, ADP, ATP ],
        rate: proc { |pool, e, master1, master2, master3|
                rc = pool * master2 / ( master1 + master2 )
                MMi.( rc, TYMS_a, TYMS_m, e, TYMS_DeoxyUMP_Km )
              }

    # Reduction of UDP into DeoxyUDP by RNR.
    RNR_UDP_DeoxyUDP = @m.Transition s: { U12P: -1, DeoxyU12P: 1 },
      domain: [ U12P, RNR, DeoxyU12P, AMP, ADP, ATP ],
        rate: proc { |pool, e, master1, master2, master3|
                rc = pool * master2 / ( master1 + master2 )
                MMi.( rc, RNR_a, RNR_m, e, RNR_UDP_Km )
              }

    # Consumption of TTP by DNA synthesis.
    DeoxyTTP_to_DNA = @m.Transition s: { DeoxyT23P: -1 },
        rate: proc { DNA_creation_speed / 4 }

    # Phosphorylation of TMP into TDP-TTP pool.
    TMPK_DeoxyTMP_DeoxyTDP = @m.Transition s: { DeoxyTMP: -1, TMPK: 0, DeoxyT23P: 1 },
      domain: [ DeoxyTMP, TMPK, ADP, DeoxyT23P, DeoxyGMP, AMP, ATP ],
        rate: proc { |rc, e, ci1, pool, ci4, master1, master3|
                master2 = ci1
                ci2 = pool * master2 / ( master2 + master3 )
                ci3 = pool * master3 / ( master2 + master3 )
                MMi.( rc, TMPK_a, TMPK_m, e, TMPK_DeoxyTMP_Km,
                      ci1 => 250.0.µM, ci2 => 30.0.µM, ci3 => 750.µM, ci4 => 117.µM )
              }
  end

  it "should work" do
    # === Simulation execution
    @m.run!
    # === Plotting of the results
    @m.plot_state
    sleep 20
  end
end
