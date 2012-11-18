#encoding: utf-8

# Emphasizing separation of concerns, the model is defined as agnostic of
# simulation settings. Only for the purpose of simulation, model is combined
# together with specific simulation settings. Simulation settings consist of
# global settings (eg. time step, sampling rate...) and object specific
# settings (eg. clamps, constraints...). Again, clamps and constraints *do not*
# belong to the model. Simulation methods are also concern of this class, not
# the model class. Thus, simulation is not done by calling instance methods of
# the model. Instead, this class makes a 'mental image' of the model and only
# that is used for actual simulation.
#
module YPetri
  class Simulation

  end # class Simulation
end # module YPetri
