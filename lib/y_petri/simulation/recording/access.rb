#encoding: utf-8

# A mixin.
# 
class YPetri::Simulation::Recording
  module Access
    # Without arguments, acts as @recording getter. If feature description hash
    # is given, it is passed to +@recording#features+ method.
    # 
    def recording nn=nil
      return @recording if nn.nil? # act as attr_reader :recording
      recording.features **nn
    end
  end # module Access
end # class YPetri::Simulation::Recording
