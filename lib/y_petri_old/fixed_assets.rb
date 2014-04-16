#encoding: utf-8

# Public command interface of YPetri.
# 
module YPetri
  GuardError = Class.new TypeError

  Place = Class.new
  Transition = Class.new
  Net = Class.new Module
  Simulation = Class.new
  Core = Class.new
  World = Class.new
  Agent = Class.new
end # module YPetri
