export default class Notification {
  constructor(game, data) {
    this.data = data
    this.$notifications = game.$game.querySelector(".notifications")
    this.$ = this.buildDiv()
    this.$notifications.appendChild(this.$)
    this.expires = null
  }

  buildDiv() {
    const div = document.createElement("div")
    div.className = `notification ${this.data.level}`
    div.innerHTML = this.data.message
    return div
  }

  isExpired() {
    return this.expires == null
  }

  render(ts) {
    if (this.expires != null) {
      if (ts > this.expires) {
        this.$.classList.remove("in")
        this.$.remove()
        this.expires = null
      }
    } else {
      this.$.classList.add("in")
      this.expires = ts + 5000
    }
  }
}
