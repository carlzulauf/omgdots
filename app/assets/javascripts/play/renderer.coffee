class @Play.Renderer
  @main: ->
    @instance = new Play.Renderer() unless @instance?

  constructor: ->
    @notifications = []
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

  pushNotification: (notification) ->
    @notifications.push notification

  render: (ts) ->
    game.render(ts) for game in @games
    if @notifications.length > 0
      survivors = []
      for notification in @notifications
        notification.render(ts)
        survivors.push(notification) unless notification.isExpired()
      @notifications = survivors