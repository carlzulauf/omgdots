// Runs keyed callbacks once their delay has passed. Pushing a key that is
// already waiting replaces its callback and restarts its delay.
export default class Deferrer {
  static main() {
    this.instance ||= new Deferrer()
    return this.instance
  }

  constructor() {
    this.jobs = {}
    this.ts = this.now()
    this.interval = window.setInterval(() => this.run(), 120)
  }

  now() {
    return Date.now()
  }

  run() {
    this.ts = this.now()
    for (const [key, job] of Object.entries(this.jobs)) {
      if (job != null && this.ts > job.ts) {
        this.jobs[key] = null
        job.callback(this.ts)
      }
    }
  }

  push(key, delay, callback) {
    const job = this.jobs[key]
    if (job != null) {
      job.ts = this.now() + delay
      job.callback = callback
    } else {
      this.jobs[key] = { ts: this.now() + delay, callback }
    }
  }
}
