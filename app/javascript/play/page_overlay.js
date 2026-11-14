export default class PageOverlay {
  constructor(game) {
    this.game = game
    this.$ = document.querySelector(".page-overlay")
    this.$title = this.$.querySelector(".title")
    this.$restartLink = this.$.querySelector(".restart-link")
    this.doShow = false
    this.isShown = false
    this.listen()
  }

  listen() {
    this.$restartLink.addEventListener("click", (e) => {
      e.preventDefault()
      this.game.restart()
    })
  }

  show() {
    this.$.classList.add("in")
    this.$title.innerHTML = this.title
    this.isShown = true
  }

  hide() {
    this.$.classList.remove("in")
    this.isShown = false
  }

  reset(state, ts) {
    this.hide()
    this.update(null, state)
  }

  render(ts) {
    if (this.doShow) {
      if (!this.isShown) this.show()
    } else if (this.isShown) {
      this.hide()
    }
  }

  update(previous, current) {
    if (current.completed_at == null && (current.won_at == null || current.play_to_end)) {
      this.doShow = false
      return
    }

    this.doShow = true
    if (this.game.isSingleDevice(current)) {
      this.title = this.singleDeviceTitle(current)
      return
    }
    const won = current.winner === this.game.findCurrentPlayerNumber(current)
    if (current.completed_at != null) {
      if (current.won_at != null) {
        this.title = won ? "You won the complete game!" : "You lost the complete game!"
      } else {
        this.title = "The game has ended in a draw."
      }
    } else {
      this.title = won ? "You won the game!" : "You lost the game!"
    }
  }

  // Both players share the screen, so name the winner instead of "you".
  singleDeviceTitle(state) {
    const winner = this.game.getPlayer(state.winner, state)
    if (winner == null) return "The game has ended in a draw."
    const name = escapeHtml(winner.name)
    return state.completed_at != null ? `${name} won the complete game!` : `${name} won the game!`
  }
}

function escapeHtml(text) {
  const div = document.createElement("div")
  div.textContent = text
  return div.innerHTML
}
