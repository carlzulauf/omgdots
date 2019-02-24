class @Play.Deferrer
  @main: ->
    @instance = new Play.Deferrer() unless @instance?

  constructor: ->
    @jobs = {}
    @ts = @now()
    @interval = window.setInterval @runCallback, 120

  now: ->
    +(new Date())

  runCallback: ->
    =>
      @ts = @now()
      for key, job of @jobs
        if @ts > job.ts
          @jobs[key] = null
          job.callback(ts)

  push: (key, delay, callback) ->
    job = @jobs[key]
    if job?
      job.ts = @now() + delay
      job.callback = callback
    else
      @job[key] = ts: @now() + delay, callback: callback
