class @Play.Renderer
  @main: ->
    @instance = new Play.Renderer() unless @instance?

  constructor: ->
    @frames = []
    @rafLoop = @buildRafLoop()
    window.requestAnimationFrame(@rafLoop)

  buildRafLoop: ->
    (ts) =>
      @ts = ts
      @render(ts)
      window.requestAnimationFrame(@rafLoop)

  pushFrame: (frame) ->
    @frames.push frame

  render: (ts) ->
    frames = @frames
    @frames = []
    frame.render(ts) for frame in frames

class @Play.Frame
  constructor: ->
    @queue = []

  render: (ts) ->
    callback(ts) for callback in @queue

  q: (callback) ->
    @queue.push callback
