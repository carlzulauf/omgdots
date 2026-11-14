// The bar above the scoreboard: which seat this device holds, a switch to
// change seat, the player's name, and a link to share the game.
export default class SeatBar {
  constructor(game) {
    this.game = game
    this.$ = this.game.$game.querySelector(".seat-bar")
    this.$digit = this.$.querySelector(".seat-digit")
    this.$label = this.$.querySelector(".seat-label")
    this.$nameInput = this.$.querySelector(".name-input")
    this.$options = [...this.$.querySelectorAll(".seat-option")]
    this.$shareUrl = this.$.querySelector(".share-url")
    this.$copy = this.$.querySelector(".share-copy")
    this.current = {}
    this.$shareUrl.value = window.location.href
    this.listen()
  }

  listen() {
    for (const option of this.$options) {
      option.addEventListener("click", () => this.select(+option.dataset.number))
    }
    this.$nameInput.addEventListener("input", () => this.nameChanged())
    this.$nameInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") this.$nameInput.blur()
    })
    this.$nameInput.addEventListener("blur", () => {
      this.saveName()
      if (this.$nameInput.value.trim() === "" && this.current.name != null) {
        this.$nameInput.value = this.current.name
      }
    })
    this.$shareUrl.addEventListener("focus", () => this.$shareUrl.select())
    this.$copy.addEventListener("click", () => this.copy())
  }

  select(number) {
    if (number === this.current.number) return
    this.game.selectPlayer(number)
  }

  nameChanged() {
    this.game.d("seat-bar.name", 1500, () => this.saveName())
  }

  saveName() {
    const name = this.$nameInput.value.trim()
    if (this.current.name != null && name !== "" && name !== this.current.name) {
      this.game.updatePlayer({ name })
    }
  }

  async copy() {
    const url = window.location.href
    this.$shareUrl.value = url
    let copied = false
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(url)
        copied = true
      }
    } catch (_error) {
      copied = false
    }
    if (!copied) copied = this.copyBySelection()
    this.flashCopy(copied ? "Copied!" : "Press Ctrl+C", copied)
  }

  // Fallback for insecure origins (e.g. a LAN IP) where navigator.clipboard
  // is unavailable. Leaves the URL selected so a manual copy also works.
  copyBySelection() {
    this.$shareUrl.focus()
    this.$shareUrl.select()
    this.$shareUrl.setSelectionRange(0, this.$shareUrl.value.length)
    try {
      return document.execCommand("copy")
    } catch (_error) {
      return false
    }
  }

  flashCopy(text, ok) {
    this.$copy.textContent = text
    this.$copy.classList.toggle("copied", ok)
    window.clearTimeout(this.copyTimer)
    this.copyTimer = window.setTimeout(() => {
      this.$copy.textContent = "Copy"
      this.$copy.classList.remove("copied")
    }, 1800)
  }

  buildCache(state) {
    const number = this.game.findCurrentPlayerNumber(state)
    const player = this.game.getPlayer(number, state)
    return { number, name: player != null ? player.name : null }
  }

  reset(state) {
    this.current = this.buildCache(state)
    this.renderSeat(this.current.number)
    this.renderName(this.current.name)
  }

  update(previous, current) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(current)
  }

  render(ts) {
    if (this.previous) {
      if (this.previous.number !== this.current.number) this.renderSeat(this.current.number)
      if (this.previous.name !== this.current.name) this.renderName(this.current.name)
      this.previous = null
    }
  }

  renderSeat(number) {
    this.$.classList.remove("seat-0", "seat-1", "seat-2")
    this.$.classList.add(`seat-${number}`)
    this.$digit.textContent = number === 0 ? "--" : number
    this.$label.textContent = number === 0 ? "Spectating" : `You are Player ${number}`
    for (const option of this.$options) {
      option.setAttribute("aria-pressed", String(+option.dataset.number === number))
    }
  }

  renderName(name) {
    this.$nameInput.hidden = name == null
    // Don't clobber what the player is typing.
    if (name != null && document.activeElement !== this.$nameInput) {
      this.$nameInput.value = name
    }
  }
}
