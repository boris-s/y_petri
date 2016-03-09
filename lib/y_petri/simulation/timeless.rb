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
      
    # TODO: But why am I doing it like this? Did I want to emphasize the standalone
    # nature of Core class? Maybe... And maybe I did it so that the runge-kutta method
    # with its @rk_core instance variable instead of @core does not have @core and #core.
    # In this manner, I'm forcing myself to rethink Simulation class.
    singleton_class.class_exec do
      attr_reader :core
      delegate :simulation_method, # this looks quite redundant with simulation.rb
               :step!,
               :firing_vector_tS,
               to: :core
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
  end # def init
end # module YPetri::Simulation::Timeless
