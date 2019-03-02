class @PlayGame
  constructor: (@id, @user) ->
    @$game = document.querySelector("#game-#{@id}")
    window.addEventListener "load", (e) =>
      @start()
      @subscribe()

  start: ->
    @renderer = Play.Renderer.main()
    @deferrer = Play.Deferrer.main()
    @components = [
      new Play.Menu(@),
      new Play.Scoreboard(@),
      new Play.Board(@),
      new Play.PageOverlay(@)
    ]
    @renderer.pushGame @

  render: (ts) ->
    for component in @components
      component.render ts

  move: (data) ->
    @channel.perform "move", data

  restart: ->
    @channel.perform "restart"

  reset: ->
    for component in @components
      component.reset @state, ts

  subscribe: ->
    options =
      channel: "PlayGameChannel"
      id: @id
      user: @user
    @channel = App.cable.subscriptions.create options,
      received: (data) =>
        @onReceive(data)

      connected: =>
        console.log "Connected to PlayGameChannel. Calling #start."
        @channel.perform "start"

  onReceive: (message) ->
    console.log ["onReceive", message]
    if message.type == "game"
      was = @state
      @state = message.data
      for component in @components
        if was? then component.update(was, @state) else component.reset(@state)
    else if message.type == "notification"
      @notify message.data

  selectPlayer: (number) ->
    @channel.perform "select_player", { number: number }

  updatePlayer: (data) ->
    @channel.perform "update_player", data

  notify: (notice) ->
    @renderer.pushNotification new Play.Notification(@, notice)

  getScore: (number, state) ->
    score = 0
    for row in state.board
      for tile in row
        score++ if tile == number
    score

  percentComplete: (state) ->
    state = @state unless state?
    total = 0
    count = 0
    lines = [4, 5, 6, 7, 8, 9]
    drawn = [5, 8]
    for row in state.board
      for col in row
        total++ if lines.includes(col)
        count++ if drawn.includes(col)
    count / total

  getPlayer: (number, state) ->
    state = @state unless state?
    switch number
      when 1 then state.player_1
      when 2 then state.player_2
      else null

  findCurrentPlayer: (state) ->
    @getPlayer @findCurrentPlayerNumber(state)

  findCurrentPlayerNumber: (state) ->
    state = @state unless state?
    return 1 if state.player_1.owner == @user
    return 2 if state.player_2.owner == @user
    0

  d: (key, delay, callback) ->
    @deferrer.push key, delay, callback

  ts: (callback) ->
    ts = @renderer.ts
    callback(ts) if callback?
    ts
