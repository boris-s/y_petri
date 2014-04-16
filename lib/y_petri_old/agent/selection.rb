class YPetri::Agent
  class Selection
    # TODO: This calls for refactor as Array subclass. No time right now...
    def initialize
      clear
    end
    def clear; @selection = [] end
    def set *aa; @selection = aa end
    def get; @selection end
    def add arg; @selection << arg end
    alias :<< :add
    def subtract arg; @selection -= arg end
  end
end
