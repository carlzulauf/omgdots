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

  def update_player(data)
    update do |game|
      player = game.find_player(@owner)
      player.assign_attributes(data) if player
    end
    notify! "Player details updated", level: "success"
  end

  def select_player(data)
    update do |game|
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

  def restart
    update(&:restart)
  end

  private

  def update(&block)
    broadcast DotsGame.for_update(@game_id, &block)
    if @after_update.present?
      broadcast @after_update
      @after_update = nil
    end
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
