# broadcast:
# DotsGameChannel.broadcast_to game, message_hash

class DotsGameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:id]
    stream_for find_game
  end

  def start
    transmit find_game
  end

  def move(data)
    broadcast update { |g| g.move(x: data["x"], y: data["y"]) }
  end

  def play_to_end
    broadcast update { |g| g.play_to_end = true }
  end

  def restart
    broadcast update(&:restart)
  end

  private

  def update(&block)
    DotsGame.for_update(@game_id, &block)
  end

  def find_game
    DotsGame.find_or_create(@game_id)
  end

  def broadcast(game)
    DotsGameChannel.broadcast_to game.id, game
  end
end
