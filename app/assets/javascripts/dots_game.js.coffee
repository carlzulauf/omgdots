class @DotsGame
  constructor: (@gameData) ->
    @id = @gameData.id
    @render()
    @subscribe()

  subscribe: ->
    options =
      channel: "DotsGameChannel"
      id: @id
    @channel = App.cable.subscriptions.create options,
      received: (data) ->
        console.log ["received", data]

      connected: ->
        console.log "Connected to DotsGameChannel"

      subscribed: ->
        console.log ["subscribed", arguments]

  render: ->
    rows = @gameData.board.map (row) =>
      cols = row.map (col) =>
        @buildTile(col)
      inner = cols.join("\n")
      """
        <div class="board-row">#{inner}</div>
      """

    html = """
             <div class="board">#{rows.join("\n")}</div>
           """
    $(".game").html html

  buildTile: (value) ->
    classNames = switch value
      when 0 then "tile empty"
      when 1 then "tile player1"
      when 2 then "tile player2"
      when 3 then "vertex"
      when 4 then "vline open"
      when 5 then "vline"
      when 6 then "hline open"
      when 7 then "hline"

    """
      <div class="#{classNames}"></div>
    """
