#encoding: utf-8

# Public command interface of YPetri.
# 
module YPetri
  DEFAULT_SIMULATION_SETTINGS = -> do
    { step_size: 0.02,
      sampling_period: 2,
      time: 0..60 }
  end

  GuardError = Class.new TypeError
end # module YPetri
