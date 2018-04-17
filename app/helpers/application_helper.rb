module ApplicationHelper
  def init_game_js(game)
    javascript_tag("window.currentGame = new DotsGame(#{game.id.to_json});")
  end

  def nbsp
    "&nbsp;".html_safe
  end

  def board_css_grid_areas(game)
    rows = board_css_table(game).map { |row| '"' + row.join(" ") + '"' }
    areas = rows.join("\n  ");
    "grid-template-areas: #{areas};"
  end

  def board_grid_css(game)
    <<~HERECSS
      grid-template-columns: repeat(#{game.width}, 10px 50px) 10px;
      grid-template-rows: repeat(#{game.height}, 10px 50px) 10px;
    HERECSS
  end

  def board_css_table(game)
    ((game.height * 2) + 1).times.map do |row|
      ((game.width * 2) + 1).times.map do |col|
        case [row % 2, col % 2]
        when [0, 0] then "dot"
        when [0, 1] then "hline"
        when [1, 0] then "vline"
        else
          "tile"
        end
      end
    end
  end
end
