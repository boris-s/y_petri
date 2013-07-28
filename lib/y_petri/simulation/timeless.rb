# encoding: utf-8

# A mixin for timeless simulations.
# 
class YPetri::Simulation
  module Timeless
    require_relative 'timeless/recorder'
    require_relative 'timeless/core'

    # False for timeless simulations.
    # 
    def timed?
      false
    end

    private

    # Initialization subroutine for timeless simulations. Sets up the
    # parametrized subclasses +@Core+ (the simulator) and +@Recorder+,
    # and initializes the +@recorder+ attribute.
    # 
    def init **settings
      init_core_and_recorder_subclasses
      puts "Hello from #init, setting up timeless @recorder"
      @recorder = Recorder().new # init the recorder
    end

    # Sets up subclasses of +Core+ (the simulator) and +Recorder+ (the sampler)
    # for timeless simulations.
    # 
    def init_core_and_recorder_subclasses
      param_class( { Core: Core, Recorder: Recorder },
                   with: { simulation: self } )
    end
  end # module Timeless
end # module YPetri::Simulation
