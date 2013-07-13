# Timed simulation -- recording.
# 
module YPetri::Simulation::Timeless
  class Recording < YPetri::Simulation::Recording
    attr_accessor :next_label

    # Like +YPetri::Simulation::Recording#reset+, allowing for additional named
    # argument +:next_sample+ that sets the label (number) of the next sample.
    # 
    def reset! **nn
      super
      self.next_label = nn[:next_label] || 0
    end

    # Records the current system state under a numbered sample.
    # 
    def sample!
      super next_label
      self.next_label = next_label.next
    end
  end
end
