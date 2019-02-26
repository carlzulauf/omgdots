class GamesController < ApplicationController
  def new
    @game = DotsGame.new
  end

  def create
    @game = DotsGame.find(game_params[:id])
    @game ||= DotsGame.create(game_params)
    redirect_to game_url(@game)
  end

  def show
    session[:uid] ||= SecureRandom.base58(8)
    @game = present(DotsGame.find_or_create(params[:id]), name: :game)
    render :play
  end

  def destroy
    DotsGame.find(params[:id])&.destroy
    redirect_to new_game_url
  end

  def game_params
    params.require(:dots_game).permit(:id, :width, :height, :must_touch)
  end
end
