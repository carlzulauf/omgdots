class DotsGameCell < Struct.new(:board, :x, :y)
  TILE_EMPTY    = 0
  TILE_PLAYER1  = 1
  TILE_PLAYER2  = 2
  DOT           = 3
  VLINE_OPEN    = 4
  VLINE_CLOSE   = 5
  VLINE_OUT     = 6
  HLINE_OPEN    = 7
  HLINE_CLOSE   = 8
  HLINE_OUT     = 9

  def type
    case value
    when HLINE_OPEN, HLINE_CLOSE, HLINE_OUT then :hline
    when VLINE_OPEN, VLINE_CLOSE, VLINE_OUT then :vline
    when DOT then :dot
    else
      :tile
    end
  end

  def css_classes
    [type, css_state].compact
  end

  def css_state
    case value
    when HLINE_CLOSE, VLINE_CLOSE then :drawn
    when HLINE_OUT, VLINE_OUT then :disabled
    when TILE_PLAYER1 then :player1
    when TILE_PLAYER2 then :player2
    end
  end

  def value
    board.data[y][x]
  end
end
