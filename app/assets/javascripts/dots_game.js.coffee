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
        @onReceive(data)

      connected: =>
        console.log "Connected to DotsGameChannel"
        @channel.perform "start"

  listen: ->
    $(".game").on "click", ".hline.open, .vline.open", (e) =>
      $el = $(e.target)
      @channel.perform "move", x: $el.data("x"), y: $el.data("y")
    $(".game-menu .restart").on "click", =>
      @channel.perform "restart"
    $(".game-overlay").on "click", ".play_to_end", =>
      @channel.perform "play_to_end"
    $(".game-overlay").on "click", ".restart", =>
      @channel.perform "restart"
    $(".game-overlay").on "click", ".exit", =>
      $(".game-menu .exit a").click()

  onReceive: (data) ->
    @gameData = data
    @render()

    overlay = false
    if data.completed_at
      if data.winner
        overlay = @buildCompleteOverlay()
      else
        overlay = @buildTieOverlay()
    else if data.winner && !data.play_to_end
      overlay = @buildWinnerOverlay()

    if overlay
      @showOverlay(overlay) unless @overlayShown
    else if @overlayShown
      @hideOverlay()

  showOverlay: (content) ->
    $board = $(".game .board")
    $overlay = $(".game-overlay")
    $overlay.html(content) if content
    w = Math.max $board.width() + 30, 300
    h = Math.max $board.height() + 30, 300
    $overlay.css
      height: h
      width: w
      marginTop: 10
      marginBottom: -(h + 10)
      opacity: 1
    @overlayShown = true

  hideOverlay: ->
    $overlay = $(".game-overlay")
    h = (@boardHeight / 2) + 25
    $overlay.html("")
    $overlay.css
      height: 0
      width: 0
      marginTop: h
      marginBottom: -h
      opacity: 0
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

  buildWinnerOverlay: ->
    @buildEnderOverlay("Game Won!", "Player #{@gameData.winner} is the winner", true)

  buildTieOverlay: ->
    @buildEnderOverlay("Draw!", "There are no more tiles and the game is even.")

  buildCompleteOverlay: ->
    @buildEnderOverlay("Complete!", "All tiles have been taken. Player #{@gameData.winner} has won!")

  buildEnderOverlay: (title, message, play_to_end = false) ->
    pte = if play_to_end then @overlayButton("play_to_end", "Play to End") else ""
    """
      <h1>#{title}</h1>
      <p>#{message}</p>
      #{pte}
      #{@overlayButton("restart", "Restart")}
      #{@overlayButton("exit", "Exit")}
    """

  overlayButton: (css_class, content) ->
    "<button class=\"#{css_class}\">#{content}</button>"

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
