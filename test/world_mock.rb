WORLD_MOCK = -> do
  p = Class.new( YPetri::Place )
  t = Class.new( YPetri::Transition )
  n = Class.new( YPetri::Net )

  def p.nw( n, *args, &block ); new( *args ).tap { |i| i.name = n } end
  def t.nw( n, *args, &block ); new( *args ).tap { |i| i.name = n } end

  [ p, t, n ].each { |klass|
    klass.tap( &:namespace! ).class_exec do
      define_method :Place do p end
      define_method :Transition do t end
      define_method :Net do n end
    end
  }
end
