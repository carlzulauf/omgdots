const EDGE = 8 // closest the share popover gets to the viewport edge

// The row of buttons between the scoreboard and the board: Share, which
// opens a popover with the game's link, and the three seat buttons.
export default class GameMenu {
  constructor(game) {
    this.game = game
    this.$ = this.game.$game.querySelector(".game-menu")
    this.$seats = [...this.$.querySelectorAll(".seat-button")]
    this.$shareButton = this.$.querySelector(".share-button")
    this.$popover = this.$.querySelector(".share-popover")
    this.$shareUrl = this.$popover.querySelector(".share-url")
    this.$copy = this.$popover.querySelector(".share-copy")
    this.current = {}
    this.$shareUrl.value = window.location.href
    this.listen()
  }

  listen() {
    for (const button of this.$seats) {
      button.addEventListener("click", () => this.select(button))
    }
    this.$popover.addEventListener("beforetoggle", (e) => {
      if (e.newState === "open") this.placePopover()
    })
    this.$popover.addEventListener("toggle", (e) => {
      if (e.newState === "open") {
        this.placePopover()
        this.$copy.focus()
      }
    })
    const replace = () => {
      if (this.$popover.matches(":popover-open")) this.placePopover()
    }
    window.addEventListener("resize", replace)
    window.addEventListener("scroll", replace, { passive: true })
    // A click outside closes the popover, but would also reach whatever is
    // underneath, such as a line on the board. Let it only close the popover.
    document.addEventListener("pointerdown", (e) => {
      this.swallowClick = this.$popover.matches(":popover-open") &&
        !this.$popover.contains(e.target) && !this.$shareButton.contains(e.target)
    }, true)
    document.addEventListener("click", (e) => {
      if (!this.swallowClick) return
      this.swallowClick = false
      e.preventDefault()
      e.stopPropagation()
    }, true)
    this.$shareUrl.addEventListener("focus", () => this.$shareUrl.select())
    this.$copy.addEventListener("click", () => this.copy())
  }

  select(button) {
    if (button.getAttribute("aria-disabled") === "true") return
    const number = +button.dataset.number
    if (number === this.current.number) return
    this.game.selectPlayer(number)
  }

  // Below the Share button, left-aligned with it, kept inside the viewport.
  placePopover() {
    const anchor = this.$shareButton.getBoundingClientRect()
    const width = this.$popover.offsetWidth || Math.min(400, window.innerWidth - 2 * EDGE)
    const left = Math.max(EDGE, Math.min(anchor.left, window.innerWidth - width - EDGE))
    this.$popover.style.left = `${left}px`
    this.$popover.style.top = `${anchor.bottom + 6}px`
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

  // In a single-device game the seat this device plays follows the turn, so
  // `number` changes with it.
  buildCache(state) {
    return {
      number: this.game.findCurrentPlayerNumber(state),
      single: this.game.isSingleDevice(state)
    }
  }

  reset(state) {
    this.current = this.buildCache(state)
    this.renderSeats(this.current)
  }

  update(previous, current) {
    if (this.previous == null) this.previous = this.current
    this.current = this.buildCache(current)
  }

  render(ts) {
    if (this.previous) {
      const { number, single } = this.previous
      if (number !== this.current.number || single !== this.current.single) this.renderSeats(this.current)
      this.previous = null
    }
  }

  renderSeats({ number, single }) {
    for (const button of this.$seats) {
      const seat = +button.dataset.number
      button.setAttribute("aria-pressed", String(seat === number))
      button.setAttribute("aria-disabled", String(single))
      const title = single ? this.singleDeviceTitle(seat, number) : null
      if (title) {
        button.title = title
      } else {
        button.removeAttribute("title")
      }
    }
  }

  // Mirrors GameHtmlPresenter#seat_button_title.
  singleDeviceTitle(seat, number) {
    if (number === 0) return "This game is played on a single device, so its seats can't be taken"
    if (seat === 0) return "This device plays both seats, so it can't spectate"
    return "Played on one device: lit for whoever's turn it is"
  }
}
