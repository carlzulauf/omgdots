class @Play.Renderer
  @main: ->
    @instance = new Play.Renderer() unless @instance?

  constructor: ->
    @frames = []
    @games = []
    @rafLoop = @buildRafLoop()
    window.requestAnimationFrame(@rafLoop)

  buildRafLoop: ->
    (ts) =>
      @ts = ts
      @render(ts)
      window.requestAnimationFrame(@rafLoop)

  pushGame: (game) ->
    @games.push game

  render: (ts) ->
    game.render(ts) for game in @games
