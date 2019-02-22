class @PlayGame
  constructor: (@id, @user) ->
    @game = document.querySelector("#game-#{@id}")
    @menu = @game.querySelector(".menu-overlay")
    @renderQueue = []

    @lastTs = 0
    @showMenuTs = 0

    window.addEventListener "load", (e) =>
      @start()
    @game.querySelector(".game-ui").addEventListener "click", =>
      @menuActivity()
    @game.querySelector(".name-input").addEventListener "keydown", =>
      @playerChangeActivity()
      @menuActivity()
    @game.querySelector(".player-1-link").addEventListener "click", =>
      @selectPlayer(1)
    @game.querySelector(".player-2-link").addEventListener "click", =>
      @selectPlayer(2)
    @game.querySelector(".spectate-link").addEventListener "click", =>
      @selectPlayer(0)
    @game.querySelector(".board").addEventListener "click", (e) =>
      cL = e.target.classList
      if cL.contains("hline") || cL.contains("vline")
        @clickLine e.target
    @subscribe()

  clickLine: (div) ->
    cL = div.classList
    if !cL.contains("drawn") && !cL.contains("disabled")
      @channel.perform "move", x: +div.dataset.x, y: +div.dataset.y

  repaint: ->
    @paintPlayer(1)
    @paintPlayer(2)
    @repaintMenu()
    @repaintBoard()

  q: (fn) ->
    @renderQueue.push fn

  paintPlayer: (number) ->
    player = @getPlayer(number)
    score = @getScore(number)
    el = @game.querySelector(".scoreboard .player#{number}")
    $name = el.querySelector(".name")
    $score = el.querySelector(".score")
    @q =>
      $name.innerText = player.name
      $score.innerText = score

  repaintBoard: ->
    c = 0
    divs = @game.querySelectorAll(".board div")
    @q =>
      for row in @state.board
        for value in row
          divs[c].className = @tileCss(value)
          c++

  repaintMenu: (state) ->
    state = @state unless state?
    playerNum = @findCurrentPlayerNumber(state)
    $player1 = @game.querySelector('.player-1-link')
    $player2 = @game.querySelector('.player-2-link')
    $spectate = @game.querySelector('.spectate-link')
    $name = @game.querySelector('.name-input')
    @q ->
      switch playerNum
        when 0
          $player1.classList.remove('active')
          $player2.classList.remove('active')
          $spectate.classList.add('active')
          $name.value = "--spectating--"
          $name.disabled = true
        when 1
          $player1.classList.add('active')
          $player2.classList.remove('active')
          $spectate.classList.remove('active')
          $name.disabled = false
          $name.value = state.player_1.name
        when 2
          $player1.classList.remove('active')
          $player2.classList.add('active')
          $spectate.classList.remove('active')
          $name.disabled = false
          $name.value = state.player_2.name


  tileCss: (value) ->
    switch value
      when 0 then "tile"
      when 1 then "tile player1"
      when 2 then "tile player2"
      when 3 then "dot"
      when 4 then "vline"
      when 5 then "vline drawn"
      when 6 then "vline disabled"
      when 7 then "hline"
      when 8 then "hline drawn"
      when 9 then "hline disabled"

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
    console.log ["onReceive", state]
    was = @state
    @state = state
    if was?
      classChanges = @findClassChanges(was, @state)
      textChanges = @findTextChanges(was, @state)
      @repaintMenuOnChange(was, @state)
      @q ->
        for [tile, className] in classChanges
          tile.className = className
        for [tile, text] in textChanges
          tile.innerText = text
    else
      @repaint()

  repaintMenuOnChange: (previous, current) ->
    if @findCurrentPlayerNumber(previous) != @findCurrentPlayerNumber(current)
      @repaintMenu(current)

  findClassChanges: (previous, current) ->
    changes = []
    i = 0
    board_was = previous.board
    $board = @game.querySelector('.board')
    playerNum = @findCurrentPlayerNumber(current)
    for row, y in current.board
      for value, x in row
        if board_was[y][x] != value
          tile = $board.children[i]
          changes.push([tile, @tileCss(value)])
        i++
    changes

  findTextChanges: (previous, current) ->
    changes = []
    score1 = @getScore(1, current.board)
    score2 = @getScore(2, current.board)
    if previous.player_1.name != current.player_1.name
      changes.push([@game.querySelector('.player1 .name'), current.player_1.name])
    if previous.player_2.name != current.player_2.name
      changes.push([@game.querySelector('.player2 .name'), current.player_2.name])
    if @getScore(1, previous.board) != score1
      changes.push([@game.querySelector('.player1 .score'), score1])
    if @getScore(2, previous.board) != score2
      changes.push([@game.querySelector('.player2 .score'), score2])
    changes

  menuActivity: ->
    @showMenuTs = @lastTs + 5000

  playerChangeActivity: ->
    @updatePlayerTs = @lastTs + 1500

  checkPlayer: (ts) ->
    if @updatePlayerTs > 0 && @updatePlayerTs < ts
      @updatePlayerTs = 0
      @updatePlayer()

  updatePlayer: ->
    name = @game.querySelector('input.name-input').value
    player = @findCurrentPlayer()
    if player? and name != player.name
      @channel.perform "update_player", { name: name }

  selectPlayer: (number) ->
    @channel.perform "select_player", { number: number }

  getScore: (number, board) ->
    score = 0
    board = @state.board unless board?
    for row in board
      for tile in row
        score++ if tile == number
    score

  getPlayer: (number) ->
    switch number
      when 1 then @state.player_1
      when 2 then @state.player_2
      else null

  findCurrentPlayer: (state) ->
    @getPlayer @findCurrentPlayerNumber(state)

  findCurrentPlayerNumber: (state) ->
    state = @state unless state?
    return 1 if state.player_1.owner == @user
    return 2 if state.player_2.owner == @user
    0

  renderMenu: ->
    if @showingMenu
      @hideMenu() if @showMenuTs < @lastTs
    else
      @showMenu() if @showMenuTs > @lastTs

  hideMenu: ->
    @menu.classList.remove("on")
    @showingMenu = false

  showMenu: ->
    @menu.classList.add("on")
    @showingMenu = true

  start: ->
    @renderLoop = (ts) =>
      @lastTs = ts
      @renderMenu(ts)
      @checkPlayer(ts)
      queue = @renderQueue
      @renderQueue = []
      queue.forEach (renderer) -> renderer(ts)
      window.requestAnimationFrame(@renderLoop)
    window.requestAnimationFrame(@renderLoop)
