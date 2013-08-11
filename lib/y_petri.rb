# encoding: utf-8

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/extract_options'
require 'active_support/inflector'

# The following are the Ruby libraries used by YPetri:
require 'gnuplot'                      # used for graph visualization
require 'csv'                          # not used at the moment
require 'graphviz'                     # used for Petri net visualization

# The following are the YSupport components used by YPetri:
require 'y_support/local_object'       # object aware of its creation scope
require 'y_support/respond_to'         # Symbol#~@ + RespondTo#===
require 'y_support/name_magic'         # naming by assignment & more
require 'y_support/unicode'            # ç means self.class
require 'y_support/typing'             # run-time assertions
require 'y_support/try'                # increased awareness in danger
require 'y_support/core_ext'           # core extensions
require 'y_support/stdlib_ext/matrix'  # matrix extensions
require 'y_support/abstract_algebra'   # 
require 'y_support/kde'                # popup file with kioclient

require_relative 'y_petri/version'
require_relative 'y_petri/fixed_assets'
require_relative 'y_petri/world'
require_relative 'y_petri/place'
require_relative 'y_petri/transition'
require_relative 'y_petri/net'
require_relative 'y_petri/simulation'
require_relative 'y_petri/core'
require_relative 'y_petri/agent'
require_relative 'y_petri/dsl'

# YPetri represents Petri net (PN) formalims.
#
# A PN consists of places and transitions. There are also arcs, "arrows"
# connecting places and transitions, but these are not considered first class
# citizens in YPetri.
#
# During PN execution (simulation), transitions act upon places and change their
# marking by adding / removing tokens as dictated by their function -- more
# precisely, their operation prescription. Borrowing more from the functional
# terminology, I define domain an codomain of a PN transition in a similar way
# to the functional domain and codomain.
#
# Hybrid Functional Petri Net (HFPN) formalism, motivated by the needs of
# modeling of cellular processes, explicitly introduces the option of having
# discrete as well as continuous places and transitions (therefrom "hybrid").
# In YPetri, the emphasis is elsewhere. Just like in modern computer languages,
# there is a fluid transition between Fixnum and Bignum, YPetri attempts for
# similarly fluid transition between Integer (ie. discrete) and floating point
# (ie. continuous) representation of token amounts and reaction speeds. Whole
# discrete / continuous issue thus becomes the business of the simulator, not
# the model.
# 
module YPetri
  class << self
    def included( receiver )
      receiver.extend YPetri::DSL
      receiver.delegate :y_petri_agent, to: "self.class"
    end
  end
end
