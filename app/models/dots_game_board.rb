class DotsGameBoard
  TILE_EMPTY    = 0
  TILE_PLAYER1  = 1
  TILE_PLAYER2  = 2
  VERTEX        = 3
  VLINE_OPEN    = 4
  VLINE_CLOSE   = 5
  VLINE_OUT     = 6
  HLINE_OPEN    = 7
  HLINE_CLOSE   = 8
  HLINE_OUT     = 9

  attr_reader :width, :height, :board

  def initialize(width, height)
    @width  = width
    @height = height
    build_board
  end

  def move(x:, y:)
    pos = @board[y].try(:[], x)
    case pos
    when HLINE_OPEN then _set(x, y, HLINE_CLOSE)
    when VLINE_OPEN then _set(x, y, VLINE_CLOSE)
    end
  end

  def as_json(*)
    @board
  end

  def build_board
    @fullh = height * 2 + 1
    @fullw = width * 2 + 1
    @board = Array.new(@fullh) { Array.new(@fullw) }
    markup_board
  end

  def markup_board
    vertex_positions.each {|x, y| _set(x, y, VERTEX) }
    hline_positions.each  {|x, y| _set(x, y, HLINE_OPEN) }
    vline_positions.each  {|x, y| _set(x, y, VLINE_OPEN) }
    tile_positions.each   {|x, y| _set(x, y, TILE_EMPTY) }
  end

  def positions
    Enumerator.new do |e|
      0.upto(@fullh - 1) { |y| 0.upto(@fullw - 1) { |x| e.yield x, y } }
    end
  end

  def tile_positions
    positions.select {|x, y| x % 2 == 1 && y % 2 == 1 }
  end

  def vertex_positions
    positions.select {|x, y| y % 2 == 0 && x % 2 == 0 }
  end

  def hline_positions
    positions.select {|x, y| y % 2 == 0 && x % 2 == 1 }
  end

  def vline_positions
    positions.select {|x, y| y % 2 == 1 && x % 2 == 0 }
  end

  def _set(x, y, value)
    @board[y][x] = value
  end
end
