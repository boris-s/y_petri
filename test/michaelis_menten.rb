#encoding: utf-8

# Function closures of Michaelis & Menten kinetics.

# Vmax from enzyme concentration and turnover number.

Vmax = λ { |enz, kcat| enz * kcat }

# Reduced Michaelis constant. Influence of competitive inhibitors to the enzyme
# is percieve as a change in the apparent Michaelis constant. The following
# function calculates that apparent Michaelis constant from the real Km and a
# hash of competitive inhibitors, consisting of pairs
# { inhibitor_concentration => inhibitor_Ki }
# 
Km_reduced = λ { |km, hash_Ki=Hash.new|
  km * hash_Ki.map { |inh_c, inh_Ki|
    inh_c / inh_Ki
  }.reduce( 1, :+ ) # 1 + Σ concentration / Ki
}

# Michaelis-Menten-Hill occupancy fraction.
# 
Occupancy = λ { |c, km, hill, hash_Ki=Hash.new|
  if hill == 1 then
    # Ordinary Michalis-Menten term.
    c / ( c + Km_reduced.( km, hash_Ki ) )
  else
    # Term with Hill kinetics.p
    c ** hill / ( c ** hill + Km_reduced.( km, hash_Ki ) ** hill )
  end
}

# Michaelis-Menten-Hill equation with competitive inhibitors.
# 
MMi = λ { |c, km, hill, enz, kcat, hash_Ki=Hash.new|
  Vmax.( enz, kcat ) * Occupancy.( c, km, hill, hash_Ki )
}
