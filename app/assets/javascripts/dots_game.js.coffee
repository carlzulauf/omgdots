class @DotsGame
  constructor: (@id) ->
    @subscribe()
    @listen()

  subscribe: ->
    options =
      channel: "DotsGameChannel"
      id: @id
    @channel = App.cable.subscriptions.create options,
      received: (data) =>
        @gameData = data
        @render()

      connected: =>
        console.log "Connected to DotsGameChannel"
        @channel.perform "start"

  listen: ->
    $(".game").on "click", ".hline.open, .vline.open", (e) =>
      $el = $(e.target)
      @channel.perform "move", x: $el.data("x"), y: $el.data("y")
    $(".game-menu .restart").on "click", =>
      @channel.perform "restart"

  render: ->
    rows = @gameData.board.board.map (row, y) =>
      cols = row.map (col, x) =>
        @buildTile(col, x, y)
      inner = cols.join("\n")
      """
        <div class="board-row">#{inner}</div>
      """

    html = """
             <div class="board">#{rows.join("\n")}</div>
           """
    $(".game").html html
    $cp = $(".game-menu .current-player")
    $cp.toggleClass("current-player1", @gameData.player == 1)
    $cp.toggleClass("current-player2", @gameData.player == 2)

  buildTile: (value, x, y) ->
    classNames = switch value
      when 0 then "tile empty"
      when 1 then "tile player1"
      when 2 then "tile player2"
      when 3 then "vertex"
      when 4 then "vline open"
      when 5 then "vline"
      when 6 then "vline out"
      when 7 then "hline open"
      when 8 then "hline"
      when 9 then "hline out"

    """
      <div class="#{classNames}" data-x=#{x} data-y=#{y}></div>
    """
