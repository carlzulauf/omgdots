class DotsGame
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def to_gid_param
    id
  end

  def self.find(id)
    self.new(id)
  end
end
