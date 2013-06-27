#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'minitest/spec'
require 'minitest/autorun'
require_relative '../../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "Simplified dTTP pathway used for demo with Dr. Chang" do
  before do
    @m = YPetri::Manipulator.new
    Cytoplasm_volume_in_litres = 5.0e-11
    NA = 6.022e23
    Pieces_per_micromolar = NA / 1_000_000 * Cytoplasm_volume_in_litres
    @m.set_step 60
    @m.set_sampling 300
    @m.set_target_time 60 * 60 * 2
    AMP = @m.Place( name: :AMP, m!: 8695.0 )
    ADP = @m.Place( name: :ADP, m!: 6521.0 )
    ATP = @m.Place( name: :ATP, m!: 3152.0 )
    Deoxycytidine = @m.Place( name: :Deoxycytidine, m!: 0.5 )
    DeoxyCTP = @m.Place( name: :DeoxyCTP, m!: 1.0 )
    DeoxyGMP = @m.Place( name: :DeoxyGMP, m!: 1.0 )
    UMP_UDP_pool = @m.Place( name: :UMP_UDP_pool, m!: 2737.0 )
    DeoxyUMP_DeoxyUDP_pool = @m.Place( name: :DeoxyUMP_DeoxyUDP_pool, m!: 0.0 )
    DeoxyTMP = @m.Place( name: :DeoxyTMP, m!: 3.3 )
    DeoxyTDP_DeoxyTTP_pool = @m.Place( name: :DeoxyTDP_DeoxyTTP_pool, m!: 5.0 )
    Thymidine = @m.Place( name: :Thymidine, m!: 0.5 )
    TK1 = @m.Place( name: :TK1, m!: 100_000 )
    TYMS = @m.Place( name: :TYMS, m!: 100_000 )
    RNR = @m.Place( name: :RNR, m!: 100_000 )
    TMPK = @m.Place( name: :TMPK, m!: 100_000 )
    TK1_kDa = 24.8
    TYMS_kDa = 66.0
    RNR_kDa = 140.0
    TMPK_kDa = 50.0
    TK1_a = 5.40
    TYMS_a = 3.80
    RNR_a = 1.00
    TMPK_a = 0.83
    @m.clamp AMP: 8695.0, ADP: 6521.0, ATP: 3152.0
    @m.clamp Deoxycytidine: 0.5, DeoxyCTP: 1.0, DeoxyGMP: 1.0
    @m.clamp Thymidine: 0.5
    @m.clamp UMP_UDP_pool: 2737.0
    # Functions
    Vmax_per_minute_per_enzyme_molecule =
      lambda { |enzyme_specific_activity_in_micromol_per_minute_per_mg,
                enzyme_molecular_mass_in_kDa|
                  enzyme_specific_activity_in_micromol_per_minute_per_mg *
                    enzyme_molecular_mass_in_kDa }
    Vmax_per_minute =
      lambda { |specific_activity, kDa, enzyme_molecules_per_cell|
               Vmax_per_minute_per_enzyme_molecule.( specific_activity, kDa ) *
                 enzyme_molecules_per_cell }
    Vmax_per_second =
      lambda { |specific_activity, kDa, enzyme_molecules_per_cell|
               Vmax_per_minute.( specific_activity,
                                 kDa,
                                 enzyme_molecules_per_cell ) / 60 }
    Km_reduced =
      lambda { |km, ki_hash={}|
               ki_hash.map { |concentration, ci_Ki|
                             concentration / ci_Ki
                           }.reduce( 1, :+ ) * km }
    Occupancy =
      lambda { |concentration, reactant_Km, compet_inh_w_Ki_hash={}|
               concentration / ( concentration +
                                 Km_reduced.( reactant_Km,
                                              compet_inh_w_Ki_hash ) ) }
    MM_with_inh_micromolars_per_second =
      lambda { |reactant_concentration,
                enzyme_specific_activity,
                enzyme_mass_in_kDa,
                enzyme_molecules_per_cell,
                reactant_Km,
                competitive_inh_w_Ki_hash={}|
                Vmax_per_second.( enzyme_specific_activity,
                                  enzyme_mass_in_kDa,
                                  enzyme_molecules_per_cell ) *
                  Occupancy.( reactant_concentration,
                              reactant_Km,
                              competitive_inh_w_Ki_hash ) }
    MMi = MM_with_inh_micromolars_per_second
    TK1_Thymidine_Km = 5.0
    TYMS_DeoxyUMP_Km = 2.0
    RNR_UDP_Km = 1.0
    DNA_creation_speed = 3_000_000_000 / ( 12 * 3600 )
    TMPK_DeoxyTMP_Km = 12.0

    # transitions
    @m.Transition name: :TK1_Thymidine_DeoxyTMP,
                  domain: [ Thymidine, TK1, DeoxyTDP_DeoxyTTP_pool, DeoxyCTP, Deoxycytidine, AMP, ADP, ATP ],
                  stoichiometry: { Thymidine: -1, DeoxyTMP: 1 },
                  rate: proc { |rc, e, pool1, ci2, ci3, master1, master2, master3|
                               ci1 = pool1 * master3 / ( master2 + master3 )
                               MMi.( rc, TK1_a, TK1_kDa, e, TK1_Thymidine_Km,
                                     ci1 => 13.5, ci2 => 0.8, ci3 => 40.0 ) }
    @m.Transition name: :TYMS_DeoxyUMP_DeoxyTMP,
                  domain: [ DeoxyUMP_DeoxyUDP_pool, TYMS, AMP, ADP, ATP ],
                  stoichiometry: { DeoxyUMP_DeoxyUDP_pool: -1, DeoxyTMP: 1 },
                  rate: proc { |pool, e, master1, master2, master3|
                          rc = pool * master2 / ( master1 + master2 )
                          MMi.( rc, TYMS_a, TYMS_kDa, e, TYMS_DeoxyUMP_Km ) }
    @m.Transition name: :RNR_UDP_DeoxyUDP,
                  domain: [ UMP_UDP_pool, RNR, DeoxyUMP_DeoxyUDP_pool, AMP, ADP, ATP ],
                  stoichiometry: { UMP_UDP_pool: -1, DeoxyUMP_DeoxyUDP_pool: 1 },
                  rate: proc { |pool, e, master1, master2, master3|
                               rc = pool * master2 / ( master1 + master2 )
                               MMi.( rc, RNR_a, RNR_kDa, e, RNR_UDP_Km ) }
    @m.Transition name: :DNA_polymerase_consumption_of_DeoxyTTP,
                  stoichiometry: { DeoxyTDP_DeoxyTTP_pool: -1 },
                  rate: proc { DNA_creation_speed / 4 }
    @m.Transition name: :TMPK_DeoxyTMP_DeoxyTDP,
                  domain: [ DeoxyTMP, TMPK, ADP,
                            DeoxyTDP_DeoxyTTP_pool,
                            DeoxyGMP, AMP, ATP ],
                  stoichiometry: { DeoxyTMP: -1, TMPK: 0, DeoxyTDP_DeoxyTTP_pool: 1 },
                  rate: proc { |rc, e, ci1, pool, ci4, master1, master3|
                               master2 = ci1
                               ci2 = pool * master2 / ( master2 + master3 )
                               ci3 = pool * master3 / ( master2 + master3 )
                               MMi.( rc, TMPK_a, TMPK_kDa, e, TMPK_DeoxyTMP_Km,
                                     ci1 => 250.0, ci2 => 30.0, ci3 => 750, ci4 => 117 ) }
  end

  it "should work" do
    @m.run!
    @m.plot_state
    sleep 3
  end
end
