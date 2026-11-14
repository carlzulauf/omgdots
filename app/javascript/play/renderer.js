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
