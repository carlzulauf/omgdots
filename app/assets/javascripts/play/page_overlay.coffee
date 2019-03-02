class @Play.PageOverlay
  constructor: (@game) ->
    @$ = document.querySelector ".page-overlay"
    @$title = @$.querySelector ".title"
    @$restartLink = @$.querySelector ".restart-link"
    @doShow = false
    @isShown = false
    @listen()

  listen: ->
    @$restartLink.addEventListener "click", (e) =>
      e.preventDefault()
      @game.restart()

  show: ->
    @$.classList.add "in"
    @$title.innerHTML = @title
    @isShown = true

  hide: ->
    @$.classList.remove "in"
    @isShown = false

  reset: (state, ts) ->
    @hide()
    @update(null, state)

  render: (ts) ->
    if @doShow
      @show() unless @isShown
    else
      @hide() if @isShown

  update: (previous, current) ->
    if !current.completed_at? && (!current.won_at? || current.play_to_end)
      @doShow = false
    else
      @doShow = true
      @title =
        if current.completed_at?
          if current.won_at?
            if current.winner == @game.findCurrentPlayerNumber(current)
              "You won the complete game!"
            else
              "You lost the complete game!"
          else
            "The game has ended in a draw."
        else
          if current.winner == @game.findCurrentPlayerNumber(current)
            "You won the game!"
          else
            "You lost the game!"
