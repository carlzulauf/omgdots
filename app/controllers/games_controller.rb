class GamesController < ApplicationController
  def show
    @game = DotsGame.find_or_create(params[:id])
  end
end
