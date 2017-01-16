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
    $(".game-menu .player1").on "click", =>
      if @overlayShown then @hideOverlay() else @showOverlay()

  showOverlay: ->
    $board = $(".game .board")
    $overlay = $(".game-overlay")
    w = Math.max $board.width() + 30, 300
    h = Math.max $board.height() + 30, 300
    $overlay.css
      height: h
      width: w
      marginTop: 10
      marginBottom: -(h + 10)
    @overlayShown = true

  hideOverlay: ->
    h = (@boardHeight / 2) + 25
    $(".game-overlay").css
      height: 0
      width: 0
      marginTop: h
      marginBottom: -h
    @overlayShown = false

  centerOverlay: ->
    unless @overlayShown
      h = (@boardHeight / 2) + 25
      $(".game-overlay").css
        marginTop: h
        marginBottom: -h

  measure: ->
    unless @board_width
      $board = $(".game .board")
      @boardWidth  = $board.width()
      @boardHeight = $board.height()

  render: ->
    rows = @gameData.board.map (row, y) =>
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
    @measure()
    @centerOverlay()

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
