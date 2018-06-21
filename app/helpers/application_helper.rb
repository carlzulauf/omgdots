module ApplicationHelper
  def init_game_js(game)
    javascript_tag("window.currentGame = new DotsGame(#{game.id.to_json});")
  end

  def init_play_js(game)
    javascript_tag("window.currentPlay = new PlayGame(#{game.id.to_json})")
  end

  def set_body_class(class_name)
    content_for :body_class, class_name
  end

  def body_class
    body_class = content_for(:body_class)
    body_class ? body_class : "default"
  end
end
