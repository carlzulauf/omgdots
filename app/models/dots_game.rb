class DotsGame
  include RedisJsonModel
  attr_accessor :width, :height, :player
  attr_reader :board

  def initialize(attributes={})
    super
    self.width  ||= 7
    self.height ||= 5
    self.board  ||= DotsGameBoard.new(width: width, height: height)
    self.player ||= 1
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
