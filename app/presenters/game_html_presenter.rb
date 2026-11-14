class GameHtmlPresenter < HtmlPresenter
  def board_div
    h.content_tag(:div, class: 'board-container') do
      h.content_tag(:div, class: 'board', style: board_div_style, data: { width: width, height: height }) do
        board_cell_divs
      end
    end
  end

  def board_div_style
    <<~HERECSS
      grid-template-columns: repeat(#{width}, 20px 64px) 20px;
      grid-template-rows: repeat(#{height}, 20px 64px) 20px;
      max-width: #{max_width}px;
    HERECSS
  end

  def max_width
    [(84 * width) + 20, 900].min
  end

  def board_cell_divs
    board.cells.map { |cell| board_cell_div(cell) }.join.html_safe
  end

  def board_cell_div(cell)
    h.content_tag(:div, nil, class: cell.css_classes, data: { x: cell.x, y: cell.y })
  end

  def players
    object.players.map do |player|
      PlayerHtmlPresenter.new(player, view_context: h)
    end
  end

  # 1 or 2 when `owner` holds a seat, 0 when spectating.
  def seat_number_for(owner)
    return 0 if owner.blank?

    find_player(owner)&.number || 0
  end

  def light_track_on
    (percent_complete * 10).round
  end

  def light_track_off
    10 - (percent_complete * 10).round
  end
end
