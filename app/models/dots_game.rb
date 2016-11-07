class DotsGame
  include ActiveModel::Model
  attr_accessor :id, :width, :height, :player
  attr_reader :board

  def initialize(attributes={})
    super
    self.width  ||= 7
    self.height ||= 5
    self.board  ||= DotsGameBoard.new(width: width, height: height)
    self.player ||= 1
  end

  def save
    $model_redis.set(key, to_json)
  end

  def key
    "game:#{id}"
  end

  def channel_key
    "dots_game:#{id}"
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

  def to_gid_param
    id
  end

  def self.find(id)
    json = $model_redis.get("game:#{id}")
    self.new(JSON.parse(json)) if json
  end

  def self.find_or_create(id)
    find(id) || self.new(id: id).tap(&:save)
  end
end
