class GameHtmlPresenter < HtmlPresenter
  def board_div
    h.content_tag(:div, class: 'board', style: board_div_style, data: { width: width, height: height }) do
      board_cell_divs
    end
  end

  def board_div_style
    <<~HERECSS
      grid-template-columns: repeat(#{width}, 20px 64px) 10px;
      grid-template-rows: repeat(#{height}, 20px 64px) 10px;
    HERECSS
  end

  def board_cell_divs
    [].tap do |tags|
      cell_coordinates.each { |x, y| tags << board_cell_div(x, y) }
    end.join.html_safe
  end

  def board_cell_div(x, y)
    h.content_tag(:div, nil, class: board_cell_class(x, y), data: { x: x, y: y })
  end

  def board_cell_class(x, y)
    case [x % 2, y % 2]
    when [0, 0] then "dot"
    when [1, 0] then "hline"
    when [0, 1] then "vline"
    else
      "tile"
    end
  end

  private

  def cell_coordinates
    Enumerator.new do |y|
      ((height * 2) + 1).times do |row|
        ((width * 2) + 1).times { |col| y << [col, row] }
      end
    end
  end
end
