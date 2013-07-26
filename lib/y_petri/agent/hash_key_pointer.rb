# Represents a pointer to a key of a specific hash associated with the pointer
# instance. Used to implement pointers of the Agent class.
# 
class YPetri::Agent::HashKeyPointer
  # Key at which the pointer points.
  # 
  attr_reader :key

  # Short text explaining what does a value of the associated hash represent.
  # 
  attr_reader :what_is_hash_value

  # Upon initalization, hash key pointer requires a hash, with which the
  # instance will be associated, a textual description explaining what does
  # a value of the associated hash represent, and the default hash key.
  # 
  def initialize( hash: nil, hash_value_is: '', default_key: nil )
    @hash = hash
    @what_is_hash_value = hash_value_is
    @default_key = default_key
  end

  # Resets the key to the default key.
  # 
  def reset; @key = @default_key end

  # Sets the pointer key to the one given in the argument.
  # 
  def set arg; @key = arg end

  # Gets the <em>value</em> paired in the hash associated with the current
  # key to which this pointer points.
  # 
  def get
    return @hash[@default_key] if @key.nil?
    @hash[@key] or raise "No #{what_is_hash_value} identified by #{arg}!"
  end
end
