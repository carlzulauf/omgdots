class DotsGame
  include RedisJsonModel

  field :player,      :integer,         default: 1
  field :width,       :integer,         default: 7
  field :height,      :integer,         default: 5
  field :board,       "DotsGameBoard",  default: :create_board
  field :must_touch,  :boolean,         default: true

  def create_board
    DotsGameBoard.new(width: width, height: height)
  end

  def eql?(other)
    %i(width height player must_touch board).all? do |f|
      public_send(f) == other.public_send(f)
    end
  end

  alias_method :==, :eql?

  def move(x:, y:)
    if board.move(x: x, y: y, player: player)
      switch_player
    end
  end

  def move!(x:, y:)
    moved = false
    success = with_lock do
      moved = move(x: x, y: y)
    end
    success && moved
  end

  def restart
    board.reset
    self.player = 1
    save
  end

  def switch_player
    self.player = player == 1 ? 2 : 1
  end
end
