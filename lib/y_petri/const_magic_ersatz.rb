#coding: utf-8

# A mixin imitating Ruby constant magic. This allows to write
#
# SomeName = SomeClass.new
#
# and the resulting object will know its #name:
#
# SomeName.name = "SomeName"
#
# This is done by searching the whole Ruby namespace for constants to which
# the object is assigned. The search is performed by calling #const_magic.
# Once the object is named, its subsequent This is only done until the name
# is found - once the object is named, its subsequent assignment to constants
# does not change its name.
#
module YPetri
  module ConstMagicErsatz
    def self.included receiver
      receiver.class_variable_set :@@instances, {}
      receiver.class_variable_set :@@nameless_instances, []
      receiver.extend ConstMagicClassMethods
    end

    # The receiver class will obtain #name pseudo getter method.
    def name
      self.class.const_magic
      name_string = self.class.instances[ self ]
      name_string.null? ? nil : name_string.to_s.demodulize
    end

    # The receiver class will obtain #name setter method
    def name= ɴ
      self.class.const_magic
      self.class.instances[ self ] = ɴ.to_s
    end

    module ConstMagicClassMethods
      # #new method will consume either:
      # 1. any parameter named :name or :ɴ from among the named parameters,
      # or,
      # 2. the first parameter from among the ordered parameters,
      # and invoke #new of the receiver class with the remaining arguments.
      def new( *args, &block )
        oo = args.extract_options!
        # consume :name named argument if it was supplied
        ɴς = if oo.∋? :name, syn!: :ɴ then oo.delete( :name ).to_s
             else Null "◉ɴ" end
        # but do not consume the first ordered argument
        # LATER: this behavior should be configurable!
        # ɴς = args.shift if args.size > 0 if ɴς.null?
        # and call #new method of the receiver class with the remaining args:
        instance = super *args, oo, &block
        # having obtained the instance, attach the name to it
        instances.merge!( instance => ɴς )

        # !!! BEGIN EVIL AND DIRTY !!!
        $YPetriManipulatorInstance
          .note_new_Petri_net_object_instance( instance ) rescue
        # !!! END !!!

        return instance
      end

      # The method will search the namespace for constants to which the objects
      # of the receiver class, that are so far nameless, are assigned, and name
      # them by the first such constant found. The method returns the number of
      # remaining nameless instances.
      def const_magic
        self.nameless_instances = 
          class_variable_get( :@@instances ).select{ |key, val| val.null? }.keys
        return 0 if nameless_instances.size == 0
        catch :no_nameless_instances do search_namespace_and_subspaces Object end
        return nameless_instances.size
      end # def const_magic

      # @@instances getter and setter for the target class
      def instances; const_magic; class_variable_get :@@instances end
      def instances= val; class_variable_set :@@instances, val end

      # @@nameless_instances getter for the target class
      def nameless_instances; class_variable_get :@@nameless_instances end
      def nameless_instances= val; class_variable_set :@@nameless_instances, val end

      # Clears @@instances & @@nameless_instances
      def forget_instances
        self.instances = {}
        self.nameless_instances = []
      end

      private
      
      # Checks all the constants in some module's namespace, recursivy
      def search_namespace_and_subspaces( ɱodule, occupied = [] )
        occupied << ɱodule.object_id           # mark the module "occupied"
        
        # Get all the constants of ɱodule namespace (in reverse - more effic.)
        const_symbols = ɱodule.constants( false ).reverse
        
        # check contents of these constant for wanted objects
        const_symbols.each do |sym|
          # puts "#{ɱodule}::#{sym}" # DEBUG
          # get the constant contents
          obj = ɱodule.const_get( sym ) rescue nil
          # is it a wanted object?
          if nameless_instances.map( &:object_id ).include? obj.object_id then
            class_variable_get( :@@instances )[ obj ] = ɱodule.name + "::#{sym}"
            nameless_instances.delete obj
            # and stop working in case there are no more unnamed instances
            throw :no_nameless_instances if nameless_instances.empty?
          end
        end
        
        # and recursively descend into the subspaces
        const_symbols.each do |sym|
          obj = ɱodule.const_get sym rescue nil # get the const value
          search_namespace_and_subspaces( obj, occupied ) unless
            occupied.include? obj.object_id if obj.kind_of? Module
        end
      end
    end # module ConstMagicClassMethods
  end # module ConstMagicErsatz
end # module YCell
