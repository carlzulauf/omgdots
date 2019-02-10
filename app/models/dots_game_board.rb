class DotsGameBoard
  TILE_EMPTY    = 0
  TILE_PLAYER1  = 1
  TILE_PLAYER2  = 2
  VERTEX        = 3
  VLINE_OPEN    = 4 # available to be selected
  VLINE_CLOSE   = 5 # already selected
  VLINE_OUT     = 6 # disabled
  HLINE_OPEN    = 7
  HLINE_CLOSE   = 8
  HLINE_OUT     = 9
  ASCII_CELLS   = ["   ", " 1 ", " 2 ", "•", " ", "|", " ", "   ", "–––", "   "]

  def self.build(width, height)
    new.build(width, height)
  end

  attr_reader :data, :fullw, :fullh, :cell_map

  def initialize(data = nil)
    self.data = data if data
  end

  def data=(data)
    @data  = data
    @fullw = data[0].length
    @fullh = data.length
    @cell_map = build_cell_map
  end

  def eql?(other)
    return false unless other
    fullw == other.fullw &&
      fullh == other.fullh &&
      positions.all?{ |x, y| get(x, y) == other.get(x, y) }
  end

  alias_method :==, :eql?

  def move(x:, y:, player:)
    @player = player
    case get(x, y)
    when HLINE_OPEN then [true, draw_hline(x, y)]
    when VLINE_OPEN then [true, draw_vline(x, y)]
    else [false, 0]
    end
  end

  def paint_open
    h_open, h_out = hline_positions.reject do |x, y|
      get(x, y) == HLINE_CLOSE
    end.partition do |x, y|
      get(x - 2, y)       == HLINE_CLOSE || # left
      get(x + 2, y)       == HLINE_CLOSE || # right
      get(x - 1, y - 1)   == VLINE_CLOSE || # top left
      get(x - 1, y + 1)   == VLINE_CLOSE || # bottom left
      get(-x + 1, y - 1)  == VLINE_CLOSE || # top right
      get(x + 1, y + 1)   == VLINE_CLOSE    # bottom right
    end
    h_open.each { |x, y| set(x, y, HLINE_OPEN) }
    h_out.each  { |x, y| set(x, y, HLINE_OUT ) }

    v_open, v_out = vline_positions.reject do |x, y|
      get(x, y) == VLINE_CLOSE
    end.partition do |x, y|
      get(x, y - 2)     == VLINE_CLOSE || # top
      get(x, y + 2)     == VLINE_CLOSE || # bottom
      get(x - 1, y - 1) == HLINE_CLOSE || # top left
      get(x + 1, y - 1) == HLINE_CLOSE || # top right
      get(x - 1, y + 1) == HLINE_CLOSE || # bottom left
      get(x + 1, y + 1) == HLINE_CLOSE    # bottom right
    end
    v_open.each { |x, y| set(x, y, VLINE_OPEN) }
    v_out.each  { |x, y| set(x, y, VLINE_OUT ) }
    self
  end

  def clean
    markup_board
    self
  end

  def build(width, height)
    self.data = Array.new(height * 2 + 1) { Array.new(width * 2 + 1) }
    clean
  end

  def complete?
    tile_positions.none? { |x, y| get(x, y) == TILE_EMPTY }
  end

  def score(player)
    tile = player == 1 ? TILE_PLAYER1 : TILE_PLAYER2
    tile_positions.count { |x, y| get(x, y) == tile }
  end

  def inspect(*)
    <<~INSPECT
      #<#{self.class}:#{object_id}
       @data=
      #{ascii(indent: 2).chomp}>
    INSPECT
  end

  def ascii(indent: 0, symbols: true)
    rows = data.map do |row|
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

  def valid_position?(x, y)
    x >= 0 && x < fullw && y >= 0 && y < fullh
  end

  def set(x, y, value)
    data[y][x] = value if valid_position?(x, y)
  end

  def get(x, y)
    data[y][x] if valid_position?(x, y)
  end

  def as_json(*)
    data
  end

  def positions
    Enumerator.new do |e|
      0.upto(fullh - 1) { |y| 0.upto(fullw - 1) { |x| e.yield x, y } }
    end
  end

  def cells
    cell_map.values
  end

  private

  def build_cell_map
    Hash[positions.map { |x, y| [ [x,y], DotsGameCell.new(data, x, y) ] }]
  end

  def draw_vline(x, y)
    set(x, y, VLINE_CLOSE)
    check_tiles [x-1, y], [x+1, y]
  end

  def draw_hline(x, y)
    set(x, y, HLINE_CLOSE)
    check_tiles [x, y-1], [x, y+1]
  end

  def check_tiles(*tiles)
    scored = 0
    tiles.each do |x, y|
      if get(x, y) == TILE_EMPTY && surrounded?(x, y)
        set(x, y, player == 1 ? TILE_PLAYER1 : TILE_PLAYER2)
        scored += 1
      end
    end
    scored
  end

  def markup_board
    vertex_positions.each {|x, y| set(x, y, VERTEX    ) }
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
end
