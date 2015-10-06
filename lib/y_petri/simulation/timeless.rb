# encoding: utf-8

# A mixin for timeless simulations.
# 
module YPetri::Simulation::Timeless
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
    # Sets up a parametrized subclass of the sampler for timeless simulation.
      param_class( { Recorder: Recorder }, with: { simulation: self } )
      @core = if @guarded then
                YPetri::Core::Timeless
                  .new( simulation: self, method: method, guarded: true )
              else
                YPetri::Core::Timeless
                  .new( simulation: self, method: method, guarded: false )
              end
      @recorder = if features_to_record then 
                    # we'll have to figure out features
                    ff = case features_to_record
                         when Array then
                           net.State.Features
                             .infer_from_nodes( features_to_record )
                         when Hash then
                           net.State.features( features_to_record )
                         end
                    Recorder().new( features: ff )
                  else
                    Recorder().new # init the recorder
                  end
    end
end # module YPetri::Simulation::Timeless
