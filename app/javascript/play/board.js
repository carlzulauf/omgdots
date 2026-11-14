class Cell {
  constructor(div, value, isTurn) {
    this.div = div
    this.value = value
    this.isTurn = isTurn
    this.css = this.buildCss()
  }

  buildCss() {
    switch (this.value) {
      case 0: return "tile"
      case 1: return "tile player1"
      case 2: return "tile player2"
      case 3: return "dot"
      case 4: return this.isTurn ? "vline" : "vline disabled"
      case 5: return "vline drawn"
      case 6: return "vline disabled"
      case 7: return this.isTurn ? "hline" : "hline disabled"
      case 8: return "hline drawn"
      case 9: return "hline disabled"
    }
  }

  render(ts) {
    this.div.className = this.css
  }
}

export default class Board {
  constructor(game) {
    this.game = game
    this.$ = this.game.$game.querySelector(".board")
    this.current = {}
    this.listen()
  }

  listen() {
    this.$.addEventListener("click", (e) => {
      const cL = e.target.classList
      if (cL.contains("hline") || cL.contains("vline")) {
        this.clickLine(e.target)
      }
    })
  }

  render(ts) {
    if (this.previous != null) {
      this.current.cells.forEach((cell, i) => {
        if (cell.css !== this.previous.cells[i].css) cell.render(ts)
      })
      this.previous = null
    }
  }

  reset(state, ts) {
    this.current = this.buildCache(state)
    for (const cell of this.current.cells) cell.render(ts)
  }

  clickLine(div) {
    const cL = div.classList
    if (!cL.contains("drawn") && !cL.contains("disabled")) {
      this.game.move({ x: +div.dataset.x, y: +div.dataset.y })
    }
  }

  update(previous, current) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(current)
  }

  buildCache(state) {
    const isTurn = this.game.findCurrentPlayerNumber(state) === state.player
    const cells = []
    for (const div of this.$.children) {
      const value = state.board[+div.dataset.y][+div.dataset.x]
      cells.push(new Cell(div, value, isTurn))
    }
    return { cells }
  }
}
