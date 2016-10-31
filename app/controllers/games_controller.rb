class GamesController < ApplicationController
  def show
    @game = DotsGame.find(params[:id])
  end
end
