export default class Menu {
  constructor(game) {
    this.game = game
    this.$ = this.game.$game.querySelector(".menu-overlay")
    this.$player1Link = this.$.querySelector(".player-1-link")
    this.$player2Link = this.$.querySelector(".player-2-link")
    this.$spectateLink = this.$.querySelector(".spectate-link")
    this.$nameInput = this.$.querySelector(".name-input")
    this.showing = false
    this.current = {}
    this.listen()
  }

  listen() {
    this.game.$game.querySelector(".game-ui").addEventListener("click", () => this.activity())
    this.$nameInput.addEventListener("keydown", () => {
      this.changed()
      this.activity()
    })
    this.$player1Link.addEventListener("click", () => this.game.selectPlayer(1))
    this.$player2Link.addEventListener("click", () => this.game.selectPlayer(2))
    this.$spectateLink.addEventListener("click", () => this.game.selectPlayer(0))
  }

  activity() {
    this.hideTs = this.game.ts() + 5000
  }

  changed() {
    this.game.d("menu.changed", 1500, () => {
      if (this.playerHasChanged()) this.game.updatePlayer(this.playerUpdates())
    })
  }

  playerHasChanged() {
    return this.current.name != null && this.$nameInput.value !== this.current.name
  }

  buildCache(state) {
    const number = this.game.findCurrentPlayerNumber(state)
    const player = this.game.getPlayer(number, state)
    return { number, name: player != null ? player.name : null }
  }

  playerUpdates() {
    return { name: this.$nameInput.value }
  }

  reset(state) {
    this.current = this.buildCache(state)
    this.renderNameInput(this.current.name)
    this.renderPlayerSelector(this.current.number)
  }

  update(previous, current) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(current)
  }

  show() {
    this.$.classList.add("on")
    this.showing = true
  }

  hide() {
    this.$.classList.remove("on")
    this.showing = false
    this.hideTs = null
  }

  renderNameInput(name) {
    if (name != null) {
      this.$nameInput.value = name
      this.$nameInput.disabled = false
    } else {
      this.$nameInput.value = "--spectating--"
      this.$nameInput.disabled = true
    }
  }

  renderPlayerSelector(number) {
    const links = [this.$spectateLink, this.$player1Link, this.$player2Link]
    links.forEach((div, i) => {
      if (i === number) {
        div.classList.add("active")
      } else {
        div.classList.remove("active")
      }
    })
  }

  render(ts) {
    if (this.previous) {
      if (this.previous.name !== this.current.name) this.renderNameInput(this.current.name)
      if (this.previous.number !== this.current.number) this.renderPlayerSelector(this.current.number)
      this.previous = null
    }
    if (this.hideTs) {
      if (this.hideTs > ts) {
        if (!this.showing) this.show()
      } else {
        this.hide()
      }
    }
  }
}
