class DotsGame
  include RedisJsonModel

  field :player,       :integer,         default: 1
  field :width,        :integer,         default: 7
  field :height,       :integer,         default: 5
  field :board,        "DotsGameBoard",  default: :create_board
  field :player_1,     "DotsGamePlayer", default: -> { create_player(1) }
  field :player_2,     "DotsGamePlayer", default: -> { create_player(2) }
  field :must_touch,   :boolean,         default: true
  field :winner,       :integer
  field :started_at,   :time
  field :won_at,       :time
  field :completed_at, :time
  field :play_to_end,  :boolean,         default: false

  delegate :percent_complete, to: :board

  def create_board
    DotsGameBoard.build(width, height)
  end

  def create_player(num)
    DotsGamePlayer.build(num)
  end

  def find_player(owner)
    [player_1, player_2].detect { |p| p.owner == owner }
  end

  def current_player
    case player
    when 1 then player_1
    when 2 then player_2
    end
  end

  def players
    [player_1, player_2]
  end

  def eql?(other)
    %i(width height player must_touch board).all? do |f|
      public_send(f) == other.public_send(f)
    end
  end

  alias_method :==, :eql?

  def owner_move(owner, **move_options)
    player = find_player(owner)
    return false if player.nil?
    player_move player, move_options
  end

  def player_move(player, **move_options)
    return false unless player == current_player
    move move_options
  end

  def move(x:, y:)
    moved, scored = board.move(x: x, y: y, player: player)
    if moved
      board.paint_open if must_touch
      scored > 0 ? check_scores : switch_player
    end
    moved
  end

  def width=(value)
    object["width"] = (2..25).cover?(value.to_i) ? value.to_i : 5
  end

  def height=(value)
    object["height"] = (2..25).cover?(value.to_i) ? value.to_i : 5
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
    self.winner = nil
    self.won_at = nil
    self.completed_at = nil
  end

  def switch_player
    self.started_at ||= Time.now
    self.player = player == 1 ? 2 : 1
  end

  def tiles_count
    width * height
  end

  def majority
    (tiles_count / 2) + 1
  end
end
