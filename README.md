# YPetri

`YPetri` is a domain model and a simulator of dynamical systems. It was inspired by the problems from the field of modelling of biochemical pathways, but on purpose, YPetri is not specific to biochemistry. As a matter of separation of concerns, YPetri caters solely to the two main concerns of modelling, model specification and simulation, excelling in the first one. YPetri implements a novel universal Petri net type, that integrating discrete/continous, deterministic/stochastic, timed/timeless and stoichiometric/nonstoichiometric dichotomies commonly seen in extended Petri nets. YPetri allows specification of any kind of dynamical system whatsoever.

## Usage

`YPetri` provides a _domain_ _specific_ _language_ (DSL) that can be loaded by:
```ruby
  require 'y_petri'
  include YPetri
```
(As a matter of terminology, DSLs used in modelling are sometimes termed _domain_ _specific_ _modelling_ _languages_ (DSMLs). This term is popular especially in engineering.) Petri net places can now be created:
```ruby
  A = Place()
  B = Place()
  places.names # you can shorten this to #pn
  #=> [:A, :B]
  # Setting their marking:
  A.marking = 2
  B.marking = 5
```
And transitions:
```ruby
  A2B = Transition stoichiometry: { A: -1, B: 1 }
  #=> #<Transition: A2B (tS) >
  A2B.stoichiometry
  #=> [-1, 1]
  A2B.s
  #=> {:A=>-1, :B=>1}
  A2B.arcs.names
  #=> [:A, :B]
  A2B.timeless?
  #=> true
  A2B.enabled?
  #=> true
```
Explanation of the keywords: _arcs_, _enabled_ are standard Petri net terms,
_stoichiometry_ means arcs with the amount of tokens to add / take from the
connected places when the transition fires, _timeless_ means that firing of
the transition is not defined in time.

We can now play the _token_ _game_:
```ruby
  places.map &:marking
  #=> [2, 5]
  A2B.fire!
  places.map &:marking
  #=> [1, 6]
  A2B.fire!
  places.map &:marking
  #=> [0, 7]
```

## Advanced usage

A Petri net is mostly used as a wiring diagram of some real-world system. Such
Petri net can then be used to generate its simulation -- represented by
`YPetri::Simulation` class. A Petri net consisting of only _timed_ transitions
can be used to generate (implicitly or explicitly) a system of ordinary
differential equations (ODE). A simulation generated from such Petri net can
then be used to solve (eg.) the initial value problem by numeric methods:
```ruby
  # Start a fresh irb session!
  require 'y_petri'
  include YPetri
  A = Place default_marking: 0.5
  B = Place default_marking: 0.5
  A_pump = Transition s: { A: -1 }, rate: proc { 0.005 }
  B_decay = Transition s: { B: -1 }, rate: 0.05
  net
  #=> #<Net: name: Top, 2pp, 2tt >
  run!
```
Simulation can now be accessed through `simulation` DSL method:
```ruby
  simulation
  #=> #<Simulation: time: 60, pp: 2, tt: 2, oid: -XXXXXXXXX>
  simulation.settings
  #=> {:method=>:pseudo_euler, :guarded=>false, :step=>0.1, :sampling=>5, :time=>0..60}
  print_recording
```
If you have `gnuplot` gem installed properly, you can view plots:
```ruby
  plot_state
  plot_flux
```
## Gillespie method

To try out another simulation method, Gillespie algorithm, open a fresh session
and type:
```ruby
require 'y_petri'
require 'sy'
require 'mathn'
include YPetri

A = Place m!: 10
B = Place m!: 10
AB = Place m!: 0
AB_association = Transition s: { A: -1, B: -1, AB: 1 }, rate: 0.1
AB_dissociation = Transition s: { AB: -1, A: 1, B: 1 }, rate: 0.1
A2B = Transition s: { A: -1, B: 1 }, rate: 0.05
B2A = Transition s: { A: 1, B: -1 }, rate: 0.07

set_step 1
set_target_time 50
set_sampling 1
set_simulation_method :gillespie

run!

print_recording
```
Again, you can visualize the results using `gnuplot` gem:
```ruby
  plot_state
```
So much for the demo for now! Thanks for trying YPetri!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
core_ext/array/