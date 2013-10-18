#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/autorun'
require_relative '../../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "Token game" do
  before do
    @m = YPetri::Agent.new
    @m.Place name: "A"
    @m.Place name: "B"
    @m.Place name: "C", marking: 7.77
    @m.Transition name: "A2B", stoichiometry: { A: -1, B: 1 }
    @m.Transition name: "C_decay", stoichiometry: { C: -1 }, rate: 0.05
  end

  it "should work" do
    @m.place( :A ).marking = 2
    @m.place( :B ).marking = 5
    @m.places.map( &:name ).must_equal [:A, :B, :C]
    @m.places.map( &:marking ).must_equal [2, 5, 7.77]
    @m.transition( :A2B ).arcs.must_equal [ @m.place( :A ), @m.place( :B ) ]
    @m.transition( :A2B ).fire!
    @m.places.map( &:marking ).must_equal [1, 6, 7.77]
    @m.transition( :A2B ).fire!
    @m.place( :A ).marking.must_equal 0
    @m.place( :B ).marking.must_equal 7
    2.times do @m.transition( :C_decay ).fire! 1 end
    @m.transition( :C_decay ).fire! 0.1
    200.times do @m.transition( :C_decay ).fire! 1 end
    assert_in_delta @m.place( :C ).marking, 0.00024, 0.00001
  end
end
