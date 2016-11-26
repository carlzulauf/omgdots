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
  ASCII_CELLS   = ["   ", " 1 ", " 2 ", "•", " ", "|", " ", "   ", "–––", "   "]

  include ActiveModel::Model
  attr_accessor :width, :height, :board, :fullw, :fullh

  def initialize(attributes={})
    super
    build_board unless @board
  end

  def move(x:, y:, player:)
    @player = player
    case get(x, y)
    when HLINE_OPEN then draw_hline(x, y)
    when VLINE_OPEN then draw_vline(x, y)
    end
  end

  def as_json(*)
    {
      width:  width,
      height: height,
      fullw:  fullw,
      fullh:  fullh,
      board:  board,
    }
  end

  def build_board
    @fullh = height * 2 + 1
    @fullw = width * 2 + 1
    @board = Array.new(@fullh) { Array.new(@fullw) }
    markup_board
  end

  def inspect(*)
    <<~INSPECT
      #<#{self.class}:#{object_id}
       w/h: #{width} x #{height}
       with verticies: #{fullw} x #{fullh}
       @board=
      #{ascii(indent: 2).chomp}>
    INSPECT
  end

  def ascii(indent: 0, symbols: true)
    rows = board.map do |row|
      line = row.map do |cell|
        symbols ? ascii_cell(cell) : cell.to_s
      end.join
    end
    l = rows.first.length
    rows.map! {|line| "[  #{line}  ]\n" }
    rows.unshift "[‾‾#{"‾" * l}‾‾]\n"
    rows.push "[__#{"_" * l}__]\n"
    rows.map{ |line| (" " * indent) + line }.join
  end

  def ascii_cell(cell)
    ASCII_CELLS[cell]
  end

  private

  def draw_vline(x, y)
    set(x, y, VLINE_CLOSE)
    check_tiles [x-1, y], [x+1, y]
  end

  def draw_hline(x, y)
    set(x, y, HLINE_CLOSE)
    check_tiles [x, y-1], [x, y+1]
  end

  def check_tiles(*tiles)
    missed = true
    tiles.each do |x, y|
      if get(x, y) == TILE_EMPTY && surrounded?(x, y)
        set(x, y, @player == 1 ? TILE_PLAYER1 : TILE_PLAYER2)
        missed = false
      end
    end
    missed
  end

  def markup_board
    vertex_positions.each {|x, y| set(x, y, VERTEX) }
    hline_positions.each  {|x, y| set(x, y, HLINE_OPEN) }
    vline_positions.each  {|x, y| set(x, y, VLINE_OPEN) }
    tile_positions.each   {|x, y| set(x, y, TILE_EMPTY) }
  end

  def surrounded?(x, y)
    get(x, y-1) == HLINE_CLOSE && # north
    get(x, y+1) == HLINE_CLOSE && # south
    get(x-1, y) == VLINE_CLOSE && # west
    get(x+1, y) == VLINE_CLOSE    # east
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

  def set(x, y, value)
    @board[y][x] = value
  end

  def get(x, y)
    @board[y][x] if @board[y]
  end
end
