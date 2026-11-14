class GameHtmlPresenter < HtmlPresenter
  def board_div
    h.content_tag(:div, class: 'board-container') do
      h.content_tag(:div, class: 'board', style: board_div_style, data: { width: width, height: height }) do
        board_cell_divs
      end
    end
  end

  # The grid is sized in units of --u (see play.scss), which the stylesheet
  # scales so the board fits the viewport width when it can.
  def board_div_style
    "--board-w: #{width}; --board-h: #{height};"
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
    seat_for(owner)&.number || 0
  end

  def seat_label_for(owner)
    seat = seat_number_for(owner)
    if single_device?
      seat.zero? ? "Spectating · Player #{player}'s turn" : "Single device · Player #{player}'s turn"
    else
      seat.zero? ? "Spectating" : "You are Player #{seat}"
    end
  end

  def seat_hint
    single_device? ? "played on one device" : "pick a seat to play"
  end

  def light_track_on
    (percent_complete * 10).round
  end

  def light_track_off
    10 - (percent_complete * 10).round
  end
end
