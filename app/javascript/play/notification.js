const LEVELS = ["success", "info", "warning", "error"]
const ICONS = { success: "✓", info: "i", warning: "!", error: "✕" }
const VISIBLE_MS = 3500
const FADE_MS = 300

// A toast floating over the top of the board. The container ignores the
// pointer, so lines underneath stay clickable while a toast is showing.
export default class Notification {
  // Most toasts kept on screen at once; older ones are dismissed early.
  static MAX_VISIBLE = 3

  constructor(game, data) {
    this.data = data
    this.level = LEVELS.includes(data.level) ? data.level : "info"
    this.$notifications = game.$game.querySelector(".notifications")
    this.$ = this.buildDiv()
    this.$notifications.appendChild(this.$)
    this.expires = null
    this.removeAt = null
    this.done = false
  }

  buildDiv() {
    const div = document.createElement("div")
    div.className = `notification ${this.level}`
    div.setAttribute("role", this.level === "error" ? "alert" : "status")
    const icon = document.createElement("span")
    icon.className = "notification-icon"
    icon.setAttribute("aria-hidden", "true")
    icon.textContent = ICONS[this.level]
    const text = document.createElement("span")
    text.className = "notification-text"
    text.textContent = this.data.message
    div.append(icon, text)
    return div
  }

  isExpired() {
    return this.done
  }

  isDismissing() {
    return this.removeAt != null
  }

  dismiss(ts) {
    if (this.isDismissing()) return
    this.$.classList.remove("in")
    this.removeAt = ts + FADE_MS
  }

  render(ts) {
    if (this.done) return
    if (this.removeAt != null) {
      if (ts > this.removeAt) {
        this.$.remove()
        this.done = true
      }
    } else if (this.expires == null) {
      this.$.classList.add("in")
      this.expires = ts + VISIBLE_MS
    } else if (ts > this.expires) {
      this.dismiss(ts)
    }
  }
}
