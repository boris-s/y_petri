# encoding: utf-8

# Guarded simulation mixin – not working yet.
# 
module YPetri::Core::Guarded
  # Guarded version of the method.
  # 
  def increment_marking_vector( delta )
    try "to update marking" do
      super( note( "Δ state if tS transitions fire once",
                   is: Δ_if_tS_fire_once ) +
             note( "Δ state if tsa transitions fire once",
                   is: Δ_if_tsa_fire_once ) )
    end
  end
  
  # Guarded version of the method.
  # 
  def A_all_fire!
    try "to fire the assignment transitions" do
      super
    end
  end
end # module YPetri::Core::Guarded
