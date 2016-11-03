class DotsGame
  attr_reader :id, :board, :width, :height

  def initialize(id, width: 7, height: 5)
    @id     = id
    @width  = width
    @height = height
    @board  = DotsGameBoard.new(width, height)
  end

  def move(x:, y:)
    @board.move(x: x, y: y)
  end

  def to_gid_param
    id
  end

  def as_json(*)
    {
      id:     id,
      width:  width,
      height: height,
      board:  board,
    }
  end

  def self.find(id)
    self.new(id)
  end
end
