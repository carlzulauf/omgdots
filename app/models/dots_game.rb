class DotsGame
  include RedisJsonModel

  field :player,       :integer,         default: 1
  field :width,        :integer,         default: 7
  field :height,       :integer,         default: 5
  field :board,        "DotsGameBoard",  default: :create_board
  field :must_touch,   :boolean,         default: true
  field :winner,       :integer
  field :won_at,       :time
  field :completed_at, :time

  def create_board
    DotsGameBoard.build(width, height)
  end

  def eql?(other)
    %i(width height player must_touch board).all? do |f|
      public_send(f) == other.public_send(f)
    end
  end

  alias_method :==, :eql?

  def move(x:, y:)
    success, scored = board.move(x: x, y: y, player: player)
    if success
      if scored > 0
        check_scores

      else
        switch_player
      end
    end
  end

  def check_scores
    ts = Time.now
    if !won? && score(player) >= majority
      self.won_at = ts
      self.winner = player
    end
    self.completed_at = ts if board.complete?
  end

  def move!(x:, y:)
    moved = false
    success = with_lock do
      moved = move(x: x, y: y)
    end
    success && moved
  end

  def won?
    won_at.present?
  end

  def complete?
    completed_at.present?
  end

  def score(player = self.player)
    board.score(player)
  end

  def restart
    board.clean
    self.player = 1
    save
  end

  def switch_player
    self.player = player == 1 ? 2 : 1
  end

  def tiles_count
    width * height
  end

  def majority
    (tiles_count / 2) + 1
  end
end
