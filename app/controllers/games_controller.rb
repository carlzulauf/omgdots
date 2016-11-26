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
    @game = DotsGame.find_or_create(params[:id])
  end

  def game_params
    params.require(:dots_game).permit(:id)
  end
end
