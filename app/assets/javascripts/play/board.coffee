class @Play.Board
  class Cell
    constructor: (@div, @value, @isTurn) ->
      @css = @buildCss()

    buildCss: ->
      switch @value
        when 0 then "tile"
        when 1 then "tile player1"
        when 2 then "tile player2"
        when 3 then "dot"
        when 4 then (if @isTurn then "vline" else "vline disabled")
        when 5 then "vline drawn"
        when 6 then "vline disabled"
        when 7 then (if @isTurn then "hline" else "hline disabled")
        when 8 then "hline drawn"
        when 9 then "hline disabled"

    render: (ts) ->
      @div.className = @css

  constructor: (@game) ->
    @$ = @game.$game.querySelector(".board")
    @current = {}
    @listen()

  listen: ->
    @$.addEventListener "click", (e) =>
      cL = e.target.classList
      if cL.contains("hline") || cL.contains("vline")
        @clickLine e.target

  render: (ts) ->
    if @previous?
      for cell, i in @current.cells
        if cell.css != @previous.cells[i].css
          cell.render(ts)
      @previous = null

  reset: (state, ts) ->
    @current = @buildCache state
    for cell in @current.cells
      cell.render(ts)

  clickLine: (div) ->
    cL = div.classList
    if !cL.contains("drawn") && !cL.contains("disabled")
      @game.move x: +div.dataset.x, y: +div.dataset.y

  update: (previous, current) ->
    @previous = @current unless @previous?
    @current = @buildCache(current)

  buildCache: (state) ->
    isTurn = @game.findCurrentPlayerNumber(state) == state.player
    cells = []
    for $div in @$.children
      value = state.board[+$div.dataset.y][+$div.dataset.x]
      cells.push new Cell($div, value, isTurn)
    cells: cells
