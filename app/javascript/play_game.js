import cable from "cable"
import Board from "play/board"
import Deferrer from "play/deferrer"
import Menu from "play/menu"
import Notification from "play/notification"
import PageOverlay from "play/page_overlay"
import Renderer from "play/renderer"
import Scoreboard from "play/scoreboard"

export default class PlayGame {
  constructor(id, user) {
    this.id = id
    this.user = user
    this.$game = document.querySelector(`#game-${this.id}`)
    window.addEventListener("load", () => {
      this.start()
      this.subscribe()
    })
  }

  start() {
    this.renderer = Renderer.main()
    this.deferrer = Deferrer.main()
    this.components = [
      new Menu(this),
      new Scoreboard(this),
      new Board(this),
      new PageOverlay(this)
    ]
    this.renderer.pushGame(this)
  }

  render(ts) {
    for (const component of this.components) component.render(ts)
  }

  move(data) {
    this.channel.perform("move", data)
  }

  restart() {
    this.channel.perform("restart")
  }

  reset() {
    // FIXME: `ts` is undefined here, as it was in the CoffeeScript original.
    // Nothing calls PlayGame#reset, so it has never mattered.
    for (const component of this.components) component.reset(this.state, ts) // eslint-disable-line no-undef
  }

  subscribe() {
    const options = { channel: "PlayGameChannel", id: this.id, user: this.user }
    this.channel = cable.subscriptions.create(options, {
      received: (data) => this.onReceive(data),
      connected: () => {
        console.log("Connected to PlayGameChannel. Calling #start.")
        this.channel.perform("start")
      }
    })
  }

  onReceive(message) {
    console.log(["onReceive", message])
    if (message.type === "game") {
      const was = this.state
      this.state = message.data
      for (const component of this.components) {
        if (was != null) {
          component.update(was, this.state)
        } else {
          component.reset(this.state)
        }
      }
    } else if (message.type === "notification") {
      this.notify(message.data)
    }
  }

  selectPlayer(number) {
    this.channel.perform("select_player", { number })
  }

  updatePlayer(data) {
    this.channel.perform("update_player", data)
  }

  notify(notice) {
    this.renderer.pushNotification(new Notification(this, notice))
  }

  getScore(number, state) {
    let score = 0
    for (const row of state.board) {
      for (const tile of row) {
        if (tile === number) score++
      }
    }
    return score
  }

  percentComplete(state) {
    if (state == null) state = this.state
    let total = 0
    let count = 0
    const lines = [4, 5, 6, 7, 8, 9]
    const drawn = [5, 8]
    for (const row of state.board) {
      for (const col of row) {
        if (lines.includes(col)) total++
        if (drawn.includes(col)) count++
      }
    }
    return count / total
  }

  getPlayer(number, state) {
    if (state == null) state = this.state
    switch (number) {
      case 1: return state.player_1
      case 2: return state.player_2
      default: return null
    }
  }

  findCurrentPlayer(state) {
    return this.getPlayer(this.findCurrentPlayerNumber(state))
  }

  findCurrentPlayerNumber(state) {
    if (state == null) state = this.state
    if (state.player_1.owner === this.user) return 1
    if (state.player_2.owner === this.user) return 2
    return 0
  }

  d(key, delay, callback) {
    this.deferrer.push(key, delay, callback)
  }

  ts(callback) {
    const ts = this.renderer.ts
    if (callback != null) callback(ts)
    return ts
  }
}
