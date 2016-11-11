# broadcast:
# DotsGameChannel.broadcast_to game, message_hash

class DotsGameChannel < ApplicationCable::Channel
  def subscribed
    @game_id = params[:id]
    stream_for DotsGame.new(id: @game_id)
  end

  def start
    transmit find_game
  end

  def move(data)
    game = find_game
    game.move(x: data["x"], y: data["y"])
    game.save
    broadcast game
  end

  def restart
    broadcast find_game.tap(&:restart)
  end

  private

  def find_game
    DotsGame.find_or_create(@game_id)
  end

  def broadcast(game)
    DotsGameChannel.broadcast_to game.id, game
  end
end
