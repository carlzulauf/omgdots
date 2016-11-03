class @DotsGame
  constructor: () ->
    @subscribe()

  subscribe: ->
    options =
      channel: "DotsGameChannel"
      id: @id
    @channel = App.cable.subscriptions.create options,
      received: (data) =>
        console.log ["received", data]
        @gameData = data
        @render()

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
      when 6 then "vline out"
      when 7 then "hline open"
      when 8 then "hline"
      when 9 then "hline out"

    """
      <div class="#{classNames}"></div>
    """
