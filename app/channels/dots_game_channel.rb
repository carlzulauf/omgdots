# broadcast:
# DotsGameChannel.broadcast_to game, message_hash

class DotsGameChannel < ApplicationCable::Channel
  def subscribed
    @game = DotsGame.find(params[:id])
    stream_for @game
  end

  def start
    transmit @game
  end

  def move(data)
    @game.move(x: data["x"], y: data["y"])
    @game.save
    broadcast_game
  end

  def restart
    @game.restart
    broadcast_game
  end

  private

  def broadcast_game
    DotsGameChannel.broadcast_to @game.id, @game
  end
end
