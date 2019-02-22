# broadcast:
# DotsGameChannel.broadcast_to game, message_hash

class PlayGameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:id]
    @owner = params[:user]
    Rails.logger.info [:subscribed, params].inspect
    stream_for find_game.id
  end

  def start
    transmit find_game
  end

  def update_player(data)
    Rails.logger.info [:update_player, data].inspect
    update do |game|
      player = game.find_player(@owner)
      player.assign_attributes(data) if player
    end
  end

  def select_player(data)
    update do |game|
      p1, p2 = game.player_1, game.player_2
      p1.owner = nil if p1.owner == @owner
      p2.owner = nil if p2.owner == @owner
      case data["number"]
      when 1
        p1.owner = @owner
        p1.last_seen_at = Time.now
      when 2
        p2.owner = @owner
        p2.last_seen_at = Time.now
      end
    end
  end

  def move(data)
    update do |game|
      game.owner_move @owner, x: data["x"], y: data["y"]
    end
  end

  private

  def update(&block)
    broadcast DotsGame.for_update(@game_id, &block)
  end

  def find_game
    DotsGame.find_or_create(@game_id)
  end

  def broadcast(game)
    self.class.broadcast_to game.id, game
  end
end
