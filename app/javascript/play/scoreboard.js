// One side of the scoreboard. A device can rename the players it owns by
// clicking their name, which turns into a text field in place.
class Player {
  constructor(game, number) {
    this.game = game
    this.number = number
    this.$ = this.game.$game.querySelector(`.scoreboard .player${this.number}`)
    this.$name = this.$.querySelector(".name")
    this.$nameText = this.$name.querySelector(".name-text")
    this.$nameInput = this.$name.querySelector(".name-input")
    this.$score = this.$.querySelector(".score")
    this.$indicator = this.$.querySelector(".turn-indicator")
    this.current = {}
    this.editing = null
    this.listen()
  }

  listen() {
    this.$nameText.addEventListener("click", () => this.startEditing())
    this.$nameText.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault()
        this.startEditing()
      }
    })
    this.$nameInput.addEventListener("input", () => {
      this.game.d(`scoreboard.name.${this.number}`, 1500, () => this.saveName())
    })
    this.$nameInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        this.$nameInput.blur()
      } else if (e.key === "Escape") {
        this.$nameInput.value = this.editing.original
        this.$nameInput.blur()
      }
    })
    this.$nameInput.addEventListener("blur", () => this.stopEditing())
  }

  render(ts) {
    if (this.previous != null) {
      if (this.current.isTurn !== this.previous.isTurn) this.renderIndicator(this.current.isTurn)
      if (this.current.score !== this.previous.score) this.renderScore(this.current.score)
      if (this.current.name !== this.previous.name) this.renderName(this.current.name)
      if (this.current.editable !== this.previous.editable) this.renderEditable(this.current.editable)
      this.previous = null
    }
  }

  buildCache(state) {
    const player = this.game.getPlayer(this.number, state)
    return {
      isTurn: state.player === this.number,
      score: this.game.getScore(this.number, state),
      name: player.name,
      editable: player.owner != null && player.owner === this.game.user
    }
  }

  reset(state) {
    this.current = this.buildCache(state)
    this.renderScore(this.current.score)
    this.renderName(this.current.name)
    this.renderIndicator(this.current.isTurn)
    this.renderEditable(this.current.editable)
  }

  renderScore(score) {
    this.$score.innerText = score
  }

  // An open text field keeps what the player is typing.
  renderName(name) {
    this.$nameText.textContent = name
  }

  renderEditable(editable) {
    this.$name.classList.toggle("editable", editable)
    if (editable) {
      this.$nameText.setAttribute("tabindex", "0")
      this.$nameText.setAttribute("role", "button")
      this.$nameText.title = "Click to rename"
    } else {
      this.$nameText.removeAttribute("tabindex")
      this.$nameText.removeAttribute("role")
      this.$nameText.removeAttribute("title")
      // The seat went to someone else mid-edit: drop the edit.
      if (this.editing != null) {
        this.$nameInput.value = this.editing.saved
        this.$nameInput.blur()
      }
    }
  }

  renderIndicator(isTurn) {
    if (isTurn) {
      this.$indicator.classList.add("on")
    } else {
      this.$indicator.classList.remove("on")
    }
  }

  startEditing() {
    if (!this.current.editable || this.editing != null) return
    this.editing = { original: this.current.name, saved: this.current.name }
    this.$nameInput.value = this.current.name
    this.$name.classList.add("editing")
    this.$nameText.hidden = true
    this.$nameInput.hidden = false
    this.$nameInput.focus()
    this.$nameInput.select()
  }

  stopEditing() {
    if (this.editing == null) return
    this.saveName()
    // Show the new name straight away; the server's update follows.
    this.$nameText.textContent = this.editing.saved
    this.editing = null
    this.$name.classList.remove("editing")
    this.$nameInput.hidden = true
    this.$nameText.hidden = false
  }

  // Runs after a pause in typing, and when the field closes.
  saveName() {
    if (this.editing == null) return
    const name = this.$nameInput.value.trim()
    if (name !== "" && name !== this.editing.saved) {
      this.editing.saved = name
      this.game.updatePlayer({ name, number: this.number })
    }
  }

  update(oldState, newState) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(newState)
  }
}

export default class Scoreboard {
  constructor(game) {
    this.game = game
    this.$lights = this.game.$game.querySelectorAll(".light-track .scoreboard-light")
    this.player1 = new Player(this.game, 1)
    this.player2 = new Player(this.game, 2)
    this.current = {}
  }

  // do a full repaint of the board. sort of an escape hatch.
  reset(state, ts) {
    this.current = this.buildCache(state)
    this.player1.reset(state, ts)
    this.player2.reset(state, ts)
    this.renderLightTrack(this.current.lights)
  }

  // called when state of game has changed
  update(previous, current) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(current)
    this.player1.update(previous, current)
    this.player2.update(previous, current)
  }

  buildCache(state) {
    return { lights: this.lightsCount(state) }
  }

  lightsCount(state) {
    return Math.round(this.game.percentComplete(state) * 10)
  }

  // called whenever frames are rendered
  render(ts) {
    if (this.previous) {
      if (this.previous.lights !== this.current.lights) this.renderLightTrack(this.current.lights)
      this.previous = null
    }
    this.player1.render(ts)
    this.player2.render(ts)
  }

  renderLightTrack(lights) {
    for (let i = 1; i <= 10; i++) {
      const light = this.$lights[i - 1]
      if (i <= lights) {
        light.classList.add("on", "flicker")
      } else {
        light.classList.remove("on", "flicker")
      }
    }
  }
}
