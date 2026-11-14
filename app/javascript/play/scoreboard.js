class Player {
  constructor(game, number) {
    this.game = game
    this.number = number
    this.$ = this.game.$game.querySelector(`.scoreboard .player${this.number}`)
    this.$name = this.$.querySelector(".name")
    this.$score = this.$.querySelector(".score")
    this.$indicator = this.$.querySelector(".turn-indicator")
    this.current = {}
  }

  render(ts) {
    if (this.previous != null) {
      if (this.current.isTurn !== this.previous.isTurn) this.renderIndicator(this.current.isTurn)
      if (this.current.score !== this.previous.score) this.renderScore(this.current.score)
      if (this.current.name !== this.previous.name) this.renderName(this.current.name)
      this.previous = null
    }
  }

  buildCache(state) {
    return {
      isTurn: state.player === this.number,
      score: this.game.getScore(this.number, state),
      name: this.game.getPlayer(this.number, state).name
    }
  }

  reset(state) {
    this.current = this.buildCache(state)
    this.renderScore(this.current.score)
    this.renderName(this.current.name)
    this.renderIndicator(this.current.isTurn)
  }

  renderScore(score) {
    this.$score.innerText = score
  }

  renderName(name) {
    this.$name.innerText = name
  }

  renderIndicator(isTurn) {
    if (isTurn) {
      this.$indicator.classList.add("on")
    } else {
      this.$indicator.classList.remove("on")
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
