class @Play.Menu
  constructor: (@game) ->
    @$ = @game.$game.querySelector(".menu-overlay")
    @$player1Link   = @$.querySelector('.player-1-link')
    @$player2Link   = @$.querySelector('.player-2-link')
    @$spectateLink  = @$.querySelector('.spectate-link')
    @$nameInput     = @$.querySelector('.name-input')
    @showing = false
    @current = {}
    @listen()

  listen: ->
    @game.$game.querySelector(".game-ui").addEventListener "click", =>
      @activity()
    @$nameInput.addEventListener "keydown", =>
      @changed()
      @activity()
    @$player1Link.addEventListener "click", =>
      @game.selectPlayer(1)
    @$player2Link.addEventListener "click", =>
      @game.selectPlayer(2)
    @$spectateLink.addEventListener "click", =>
      @game.selectPlayer(0)

  activity: ->
    @hideTs = @game.ts() + 5000

  changed: ->
    @game.d 'menu.changed', 1500, =>
      if @playerHasChanged()
        @game.updatePlayer @playerUpdates()

  playerHasChanged: ->
    @current.name? && @$nameInput.value != @current.name

  buildCache: (state) ->
    number = @game.findCurrentPlayerNumber(state)
    player = @game.getPlayer(number, state)
    number: number
    name: (if player? then player.name else null)

  playerUpdates: ->
    name: @$nameInput.value

  reset: (state) ->
    @current = @buildCache state
    @renderNameInput @current.name
    @renderPlayerSelector @current.number

  update: (previous, current) ->
    @previous = @current unless @previous?
    @current = @buildCache current

  show: ->
    @$.classList.add("on")
    @showing = true

  hide: ->
    @$.classList.remove("on")
    @showing = false
    @hideTs = null

  renderNameInput: (name) ->
    if name?
      @$nameInput.value = name
      @$nameInput.disabled = false
    else
      @$nameInput.value = "--spectating--"
      @$nameInput.disabled = true

  renderPlayerSelector: (number) ->
    for div, i in [@$spectateLink, @$player1Link, @$player2Link]
      if i == number
        div.classList.add 'active'
      else
        div.classList.remove 'active'

  render: (ts) ->
    if @previous
      if @previous.name != @current.name
        @renderNameInput @current.name
      if @previous.number != @current.number
        @renderPlayerSelector @current.number
      @previous = null
    if @hideTs
      if @hideTs > ts
        @show() unless @showing
      else
        @hide()
