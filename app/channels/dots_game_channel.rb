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
    transmit @game
  end
end
