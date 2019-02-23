class PlayerHtmlPresenter < HtmlPresenter
  def div_class
    "player#{number}"
  end

  def indicator_class(game)
    return unless object == game.current_player
    "on"
  end
end
