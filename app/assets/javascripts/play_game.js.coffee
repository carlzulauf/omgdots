class @PlayGame
  constructor: (@id, @user) ->
    @$game = document.querySelector("#game-#{@id}")
    @frame = @buildFrame()
    window.addEventListener "load", (e) =>
      @start()
      @subscribe()

  start: ->
    @renderer = Play.Renderer.main()
    @deferrer = Play.Deferrer.main()
    @components = [
      new Play.Menu(@),
      new Play.Scoreboard(@),
      new Play.Board(@)
    ]
    @renderFrame()

  buildFrame: ->
    frame = new Play.Frame()
    frame.q (ts) => @render(ts)
    frame

  renderFrame: ->
    frame = @frame
    @frame = @buildFrame()
    @renderer.pushFrame @frame

  render: (ts) ->
    for component in @components
      component.render ts

  move: (data) ->
    @channel.perform "move", data

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

  onReceive: (state) ->
    was = @state
    @state = state
    for component in @components
      if was? then component.update(was, state) else component.reset(state)
    @renderFrame()

  selectPlayer: (number) ->
    @channel.perform "select_player", { number: number }

  getScore: (number, board) ->
    score = 0
    board = @state.board unless board?
    for row in board
      for tile in row
        score++ if tile == number
    score

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

  q: (callback) ->
    @frame.q callback

  ts: ->
    @renderer.ts
