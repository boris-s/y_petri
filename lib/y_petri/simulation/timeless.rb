# encoding: utf-8

# A mixin for timeless simulations.
# 
class YPetri::Simulation
  module Timeless
    require_relative 'timeless/recorder'

    # False for timeless simulations.
    # 
    def timed?
      false
    end

    # Changing the simulation method on the fly not supported.
    # 
    def set_simulation_method
      fail NoMethodError, "Changing simulation method on the fly not supported!"
    end

    private

    # Initialization subroutine for timeless simulations. Sets up the
    # parametrized subclasses +@Core+ (the simulator) and +@Recorder+,
    # and initializes the +@recorder+ attribute.
    # 
    def init **settings
      method = settings[:method] # the simulation method
      features_to_record = settings[:record]
      init_core_and_recorder_subclasses
      @core = Core().new( method: method, guarded: guarded )
      @recorder = if features_to_record then 
                    # we'll have to figure out features
                    ff = case features_to_record
                         when Array then
                           net.State.Features
                             .infer_from_elements( features_to_record )
                         when Hash then
                           net.State.features( features_to_record )
                         end
                    Recorder().new( features: ff )
                  else
                    Recorder().new # init the recorder
                  end
    end

    # Sets up subclasses of +Core+ (the simulator) and +Recorder+ (the sampler)
    # for timeless simulations.
    # 
    def init_core_and_recorder_subclasses
      param_class( { Core: YPetri::Core::Timeless,
                     Recorder: Recorder },
                   with: { simulation: self } )
    end
  end # module Timeless
end # module YPetri::Simulation
