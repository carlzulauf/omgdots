class GamesController < ApplicationController
  def new
    @game = DotsGame.new
  end

  def create
    @game = DotsGame.find(game_params[:id])
    @game ||= build_game.tap(&:save)
    redirect_to game_url(@game)
  end

  def show
    ensure_uid
    @game = present(DotsGame.find_or_create(params[:id]), name: :game)
  end

  def game_params
    params.require(:dots_game).permit(:id, :width, :height, :must_touch, :mode)
  end

  private

  # A single-device game belongs to the device that created it, which holds
  # both seats from the start.
  def build_game
    DotsGame.new(game_params).tap do |game|
      game.claim_device(ensure_uid) if game.single_device?
    end
  end

  def ensure_uid
    session[:uid] ||= SecureRandom.base58(8)
  end
end
