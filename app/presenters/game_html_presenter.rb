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
end
