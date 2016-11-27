class DotsGame
  include RedisJsonModel
  attr_accessor :player
  attr_reader :width, :height, :board, :must_touch

  def initialize(attributes={})
    super
    @width    ||= 7
    @height   ||= 5
    @board    ||= DotsGameBoard.new(width: width, height: height)
    @player   ||= 1
    @must_touch = true unless defined?(@must_touch)
  end

  def eql?(other)
    %i(width height player must_touch board).all? do |f|
      public_send(f) == other.public_send(f)
    end
  end

  alias_method :==, :eql?

  def width=(value)
    @width = value.to_i
  end

  def height=(value)
    @height = value.to_i
  end

  def must_touch=(value)
    @must_touch = case value
                  when String
                    !!(value =~ /t(rue)?|y(es)?|on/i)
                  else
                    !!value
                  end
  end

  def board=(board_data)
    if board_data.is_a?(DotsGameBoard)
      @board = board_data
    else
      @board = DotsGameBoard.new(board_data)
    end
  end

  def move(x:, y:)
    if @board.move(x: x, y: y, player: player)
      switch_player
    end
  end

  def restart
    @board.build_board
    @player = 1
    save
  end

  def switch_player
    self.player = player == 1 ? 2 : 1
  end
end
