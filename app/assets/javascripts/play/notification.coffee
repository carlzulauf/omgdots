class @Play.Notification
  constructor: (game, @data) ->
    @$notifications = game.$game.querySelector(".notifications")
    @$ = @buildDiv()
    @$notifications.appendChild @$
    @expires = null
  
  buildDiv: ->
    div = document.createElement("div")
    div.className = "notification #{@data.level}"
    div.innerHTML = @data.message
    div

  isExpired: ->
    if @expires? then false else true

  render: (ts) ->
    if @expires?
      if ts > @expires
        @$.classList.remove "in"
        @$.remove()
        @expires = null
    else
      @$.classList.add "in"
      @expires = ts + 5000