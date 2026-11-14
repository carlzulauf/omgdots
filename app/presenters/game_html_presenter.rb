class GameHtmlPresenter < HtmlPresenter
  # The game menu's seat buttons: number (0 is Spectator), label, short label.
  SEAT_BUTTONS = [[1, "Player 1", "P1"], [2, "Player 2", "P2"], [0, "Spectator", "Watch"]].freeze

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

  # How a seat button in the game menu starts out for `owner` (number 0 is
  # Spectator). GameMenu (app/javascript/play/game_menu.js) keeps it current.
  def seat_button_state(number, owner)
    seat = seat_number_for(owner)
    { pressed: number == seat, disabled: single_device?, title: seat_button_title(number, seat) }
  end

  # Mirrored by GameMenu#singleDeviceTitle.
  def seat_button_title(number, seat)
    return unless single_device?
    if seat.zero?
      "This game is played on a single device, so its seats can't be taken"
    elsif number.zero?
      "This device plays both seats, so it can't spectate"
    else
      "Played on one device: lit for whoever's turn it is"
    end
  end

  def light_track_on
    (percent_complete * 10).round
  end

  def light_track_off
    10 - (percent_complete * 10).round
  end
end
