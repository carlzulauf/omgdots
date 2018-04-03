module ApplicationHelper
  def init_game_js(game)
    javascript_tag("window.currentGame = new DotsGame(#{game.id.to_json});")
  end

  def nbsp
    "&nbsp;".html_safe
  end
end
