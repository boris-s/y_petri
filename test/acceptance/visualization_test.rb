#! /usr/bin/ruby
# encoding: utf-8

require 'minitest/autorun'
require_relative '../../lib/y_petri'     # tested component itself
# require 'y_petri'
# require 'sy'

describe "Graphviz visualization" do
  before do
    @m = YPetri::Agent.new
    @m.Place name: :A, m!: 1
    @m.Place name: :B, m!: 1.5
    @m.Place name: :C, m!: 2
    @m.Place name: :D, m!: 2.5
    @m.Transition name: :A_pump, s: { A: -1 }, rate: proc { 0.005 }
    @m.Transition name: :B_decay, s: { B: -1 }, rate: 0.05
    @m.Transition name: :C_guard, codomain: :C, assignment: -> { 2 }
  end

  it "should work" do
    @m.net.visualize
  end
end

describe "Another visualization" do
  before do
    class Object
      include YPetri
    end
    A = Place()
    B = Place()
    A2B = Transition( s: { A: -1, B: 1 } )
  end

  it "should visualize as expected" do
    net.visualize
  end
end
