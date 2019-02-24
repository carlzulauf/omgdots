class @Play.Scoreboard
  class Player
    constructor: (@game, @number) ->
      @$          = @game.$game.querySelector(".scoreboard .player#{@number}")
      @$name      = @$.querySelector(".name")
      @$score     = @$.querySelector(".score")
      @$indicator = @$.querySelector('.turn-indicator')
      @current = {}

    render: (ts) ->
      if @previous
        if @current.isTurn != @previous.isTurn
          @renderIndicator @current.isTurn
        if @current.score != @previous.score
          @renderScore @current.score
        if @current.name != @previous.name
          @renderName @current.name
        @previous = null

    buildCache: (state) ->
      isTurn: state.player == @number
      score: @game.getScore(@number, state)
      name: @game.getPlayer(@number, state).name

    reset: (state) ->
      @current = @buildCache(state)
      @renderScore @current.score
      @renderName @current.name
      @renderIndicator @current.isTurn

    renderScore: (score) ->
      @$score.innerText = score

    renderName: (name) ->
      @$name.innerText = name

    renderIndicator: (isTurn) ->
      if isTurn
        @$indicator.classList.add("on")
      else
        @$indicator.classList.remove("on")

    update: (oldState, newState) ->
      @previous = @current unless @previous?
      @current = @buildCache(newState)

  constructor: (@game) ->
    @$lights = @game.$game.querySelectorAll '.light-track .scoreboard-light'
    @player1 = new Player(@game, 1)
    @player2 = new Player(@game, 2)
    @current = {}

  # do a full repaint of the board. sort of an escape hatch.
  reset: (state, ts) ->
    @current = @buildCache(state)
    @player1.reset(state, ts)
    @player2.reset(state, ts)
    @renderLightTrack state.lights

  # called when state of game has changed
  update: (previous, current) ->
    @previous = @current unless @previous?
    @current = @buildCache(current)
    @player1.update(previous, current)
    @player2.update(previous, current)

  buildCache: (state) ->
    lights: @lightsCount(state)

  lightsCount: (state) ->
    total = 0
    count = 0
    lines = [4, 5, 6, 7, 8, 9]
    drawn = [5, 8]
    for row in state.board
      for col in row
        total++ if lines.includes(col)
        count++ if drawn.includes(col)
    Math.round (count / total) * 10

  # called whenever frames are rendered
  render: (ts) ->
    if @previous
      if @previous.lights != @current.lights
        @renderLightTrack @current.lights
      @previous = null

  renderLightTrack: (lights) ->
    for i in [1..10]
      if i <= lights
        @$lights[i - 1].classList.add("on")
        @$lights[i - 1].classList.add("flicker")
      else
        @$lights[i - 1].classList.remove("on")
        @$lights[i - 1].classList.remove("flicker")
