class DotsGame
  attr_reader :id, :board

  def initialize(id, width: 7, height: 5)
    @id = id
    @board = DotsGameBoard.new(width, height)
  end

  def to_gid_param
    id
  end

  def as_json(*)
    {
      id:     id,
      width:  board.width,
      height: board.height,
      board:  board,
    }
  end

  def self.find(id)
    self.new(id)
  end
end
