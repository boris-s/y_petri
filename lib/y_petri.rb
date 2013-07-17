#encoding: utf-8

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/extract_options'
require 'active_support/inflector'

# The following are Ruby libraries used by YPetri:
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
require 'y_support/core_ext/hash'      # hash extensions
require 'y_support/core_ext/array'     # array extensions
require 'y_support/stdlib_ext/matrix'  # matrix extensions
require 'y_support/abstract_algebra'   # 
require 'y_support/kde'                # popup file with kioclient

require_relative 'y_petri/version'
require_relative 'y_petri/fixed_assets'
require_relative 'y_petri/dependency_injection'
require_relative 'y_petri/place'
require_relative 'y_petri/transition'
require_relative 'y_petri/net'
require_relative 'y_petri/simulation'
require_relative 'y_petri/workspace'
require_relative 'y_petri/manipulator'
require_relative 'y_petri/dsl'

# YPetri represents Petri net (PN) formalism.
#
# A PN consists of places and transitions. There are also arcs, that is,
# "arrows" connecting places and transitions, though arcs are not considered
# first class citizens in YPetri.
#
# At the time of PN execution (or simulation), transitions act upon places
# and change their marking by placing or removing tokens as dictated by
# their operation method ("function").
#
# Hybrid Functional Petri Net formalism, motivated by modeling cellular
# processes by their authors' Cell Illustrator software, explicitly
# introduces the possibility of both discrete and continuous places and
# transitions ('Hybrid'). YPetri does not emphasize this. Just like there is
# fluid transition between Fixnum and Bignum, there should be fluid
# transition between token amount representation as Integer (discrete) or
# Float (continuous) - the decision should be on the simulator.
# 
module YPetri
  class << self
    def included( receiver )
      receiver.extend YPetri::DSL
      receiver.delegate :y_petri_manipulator, to: :class
    end
  end
end
