// One requestAnimationFrame loop that renders every game and notification.
export default class Renderer {
  static main() {
    this.instance ||= new Renderer()
    return this.instance
  }

  constructor() {
    this.notifications = []
    this.games = []
    this.rafLoop = (ts) => {
      this.ts = ts
      this.render(ts)
      window.requestAnimationFrame(this.rafLoop)
    }
    window.requestAnimationFrame(this.rafLoop)
  }

  pushGame(game) {
    this.games.push(game)
  }

  pushNotification(notification) {
    this.notifications.push(notification)
    // Keep the toast stack short: dismiss the oldest beyond the limit.
    const showing = this.notifications.filter((n) => !n.isDismissing())
    const limit = notification.constructor.MAX_VISIBLE
    for (const old of showing.slice(0, Math.max(0, showing.length - limit))) {
      old.dismiss(this.ts ?? 0)
    }
  }

  render(ts) {
    for (const game of this.games) game.render(ts)
    if (this.notifications.length > 0) {
      const survivors = []
      for (const notification of this.notifications) {
        notification.render(ts)
        if (!notification.isExpired()) survivors.push(notification)
      }
      this.notifications = survivors
    }
  }
}
