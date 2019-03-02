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

  def channel_key
    "game:#{id}"
  end

  def as_typed_json
    {
      type: 'game',
      data: as_json
    }
  end

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
    get_player player
  end

  def get_player(number)
    case number
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
      scored > 0 ? check_scores(player) : switch_player
    end
    moved
  end

  def width=(value)
    object["width"] = (2..25).cover?(value.to_i) ? value.to_i : 5
  end

  def height=(value)
    object["height"] = (2..25).cover?(value.to_i) ? value.to_i : 5
  end

  def check_scores(player)
    ts = Time.now
    mark_winner(player, ts) if winning_score?(player)
    self.completed_at = ts if board.complete?
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
    self.player = [1, 2].sample
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

  def winning_score?(player)
    return false if won?
    score(player) >= majority
  end

  def mark_winner(player, ts)
    self.winner = player
    self.won_at = ts
  end

  def majority
    (tiles_count / 2) + 1
  end
end
