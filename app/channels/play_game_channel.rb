class PlayGameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:id]
    @owner = params[:user]
    Rails.logger.info [:subscribed, params].inspect
    stream_for find_game.channel_key
    stream_for build_notification.channel_key
  end

  def start
    transmit find_game.as_typed_json
  end

  # `number` picks which of the owner's seats to rename. A single-device game
  # holds both, so it names either player; otherwise it is the owner's seat.
  def update_player(data)
    update do |game|
      player = owned_player(game, data["number"])
      player.assign_attributes(data.slice("name")) if player
    end
    notify! "Player details updated", level: "success"
  end

  def select_player(data)
    update do |game|
      if game.single_device?
        notify_after_update! "This game is played on a single device, so its seats can't be taken. You can watch.",
          level: "info"
        next
      end
      game.players.each { |player| player.owner = nil if player.owner == @owner }
      if (player = game.get_player(data["number"]))
        if player.can_be_owned_by?(@owner)
          player.own @owner
          notify_after_update! "Successfully became Player #{data['number']}", level: "success"
        else
          notify_after_update! "Player #{data['number']} is already owned by someone else", level: "error"
        end
      else
        notify_after_update! "You are now spectating", level: "info"
      end
    end
  end

  def move(data)
    update do |game|
      unless game.owner_move @owner, x: data["x"], y: data["y"]
        notify_after_update! "Not your turn", level: "warning"
      end
    end
  end

  # Only the device playing a single-device game can restart it.
  def restart
    update do |game|
      game.restart unless game.single_device? && game.seat_for(@owner).nil?
    end
  end

  private

  def update(&block)
    broadcast DotsGame.for_update(@game_id, &block)
    if @after_update.present?
      broadcast @after_update
      @after_update = nil
    end
  end

  def owned_player(game, number)
    return game.find_player(@owner) if number.blank?
    player = game.get_player(number.to_i)
    player if player && @owner.present? && player.owner == @owner
  end

  def find_game
    DotsGame.find_or_create(@game_id)
  end

  def build_notification(message = nil, level: Notification::DEFAULT_LEVEL)
    Notification.new(game_id: @game_id, owner: @owner, message: message, level: level)
  end

  def notify_after_update!(message, level:)
    @after_update = build_notification(message, level: level)
  end

  def notify!(message, level:)
    broadcast build_notification(message, level: level)
  end

  def broadcast(obj)
    self.class.broadcast_to obj.channel_key, obj.as_typed_json
  end
end
