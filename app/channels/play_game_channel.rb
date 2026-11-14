class PlayGameChannel < ApplicationCable::Channel
  # While this subscription is open, the owner's seats count as occupied:
  # refresh their `last_seen_at` well inside DotsGamePlayer::TIMEOUT.
  periodically :heartbeat, every: DotsGamePlayer::HEARTBEAT

  # Every retry of the optimistic update lost to another write.
  rescue_from RedisJsonModel::ConflictError do
    broadcast notice("The game was too busy to save that. Please try again.", level: "error")
  end

  # Longest player name; matches the name input's maxlength in games/show.
  NAME_LENGTH = 24

  # The owner is the connection's session uid (see ApplicationCable::Connection).
  # Any `user` param a client sends is ignored.
  def subscribed
    @game_id = params[:id]
    @owner = connection.uid
    Rails.logger.info [:subscribed, params].inspect
    stream_for find_game.channel_key
    stream_for build_notification.channel_key
    update_seats(&:seen!)
  end

  # Marks the owner's seats away. They stay reserved until the takeover
  # window runs out, so a reload or a short drop doesn't lose them.
  def unsubscribed
    update_seats(&:left!)
  end

  def start
    transmit find_game.as_typed_json
  end

  # Run by the periodic timer above; clients may also send it.
  def heartbeat
    update_seats(&:seen!)
  end

  # `number` picks which of the owner's seats to rename. A single-device game
  # holds both, so it names either player; otherwise it is the owner's seat.
  def update_player(data)
    name = data["name"].to_s.strip.first(NAME_LENGTH)
    update do |game|
      if (player = owned_player(game, data["number"]))
        next notice("A player's name can't be blank", level: "warning") if name.empty?

        player.name = name
        notice "Player details updated", level: "success"
      else
        notice "You can only rename your own seat", level: "warning"
      end
    end
  end

  # Checks the requested seat before touching the current one, so a refused
  # request leaves the owner where they were.
  def select_player(data)
    update do |game|
      if game.single_device?
        next notice("This game is played on a single device, so its seats can't be taken. You can watch.",
          level: "info")
      end

      number = data["number"].to_i
      seat = game.get_player(number)
      if seat.nil?
        game.seats_of(@owner).each(&:release)
        notice "You are now spectating", level: "info"
      elsif seat.can_be_owned_by?(@owner)
        game.seats_of(@owner).each(&:release)
        seat.own @owner
        notice "Successfully became Player #{number}", level: "success"
      else
        notice "Player #{number} is already owned by someone else", level: "error"
      end
    end
  end

  def move(data)
    update do |game|
      notice "Not your turn", level: "warning" unless game.owner_move(@owner, x: data["x"], y: data["y"])
    end
  end

  # Only the device playing a single-device game can restart it.
  def restart
    update do |game|
      game.restart unless game.single_device? && game.seat_for(@owner).nil?
      nil
    end
  end

  private

  # Applies the block to the game atomically and broadcasts the result. The
  # block may return a Notification for this owner, sent after the game. It is
  # kept per call (not on the channel) so concurrent actions on one connection
  # can't overwrite each other's, and it is re-evaluated if the update retries.
  # Any action also counts as the owner being seen.
  def update
    pending = nil
    game = DotsGame.for_update(@game_id) do |g|
      result = yield g
      pending = result.is_a?(Notification) ? result : nil
      g.seats_of(@owner).each(&:seen!)
    end
    broadcast game
    broadcast pending if pending
  end

  # Applies `block` to each seat the owner holds, skipping the write when they
  # hold none. Broadcasts only when a seat's away flag flips, so heartbeats
  # stay quiet.
  def update_seats(&block)
    return if @owner.blank?
    return if DotsGame.find(@game_id)&.seats_of(@owner).blank?

    flipped = false
    game = DotsGame.for_update(@game_id) do |g|
      seats = g.seats_of(@owner)
      was = seats.map(&:away)
      seats.each(&block)
      flipped = seats.map(&:away) != was
    end
    broadcast game if flipped
  rescue RedisJsonModel::RecordMissing
    nil # the game was deleted; nothing to keep
  end

  def owned_player(game, number)
    return game.find_player(@owner) if number.blank?
    player = game.get_player(number.to_i)
    player if player&.owned_by?(@owner)
  end

  def find_game
    DotsGame.find_or_create(@game_id)
  end

  def build_notification(message = nil, level: Notification::DEFAULT_LEVEL)
    Notification.new(game_id: @game_id, owner: @owner, message: message, level: level)
  end
  alias_method :notice, :build_notification

  def broadcast(obj)
    self.class.broadcast_to obj.channel_key, obj.as_typed_json
  end
end
