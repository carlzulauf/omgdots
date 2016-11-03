# broadcast:
# DotsGameChannel.broadcast_to game, message_hash

class DotsGameChannel < ApplicationCable::Channel
  def subscribed
    game = DotsGame.find(params[:id])
    stream_for game
    transmit game
  end
end
