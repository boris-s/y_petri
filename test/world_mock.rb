WORLD_MOCK = -> do
  w = YPetri::World.new
  [ w.Place, w.Transition, w.Net ].tap do |p, t, _|
    def p.nw( n, *args, &block )
      new( *args ).tap { |i| i.name = n }
    end

    def t.nw( n, *args, &block )
      new( *args ).tap { |i| i.name = n }
    end
  end
end
