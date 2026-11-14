// Headless Chromium screenshots and recordings over the DevTools protocol.
// Run it through bin/claude-shot; see doc/changelog/README.md for usage.
//
//   claude-shot URL [OUT.png] [flags...]     flags become steps, in order
//   claude-shot --script flow.json [vars]    steps from a JSON file
//
// Each step is an object with one action key (plus options):
//   {"goto": "/path or URL"}              navigate and wait for load
//   {"click": "css selector"}             real mouse click on the element's center
//   {"clickAt": [x, y]}                   real mouse click at viewport x,y
//   {"fill": "css selector", "text": ""}  set an input/select value (fires input+change)
//   {"eval": "js", "as": "name"}          run JS (awaited); "as" stores the result as ${name}
//   {"key": "Escape"}                     press a key (Escape, Enter, Tab, Backspace, or one character)
//   {"type": "text"}                      type text into the focused element
//   {"grant": ["clipboardReadWrite"]}     grant permissions to the current context
//   {"wait": 500}                         sleep ms
//   {"waitFor": "css selector"}           wait until it exists (timeout 10s)
//   {"scroll": [x, y]}                    window.scrollTo(x, y)
//   {"size": "375x667"}                   resize the current context's viewport
//   {"colorScheme": "dark"}               emulate prefers-color-scheme (dark | light)
//   {"ctx": "p2"}                         switch to (or create) a separate browser context
//   {"shot": "out.png", "full": true}     screenshot; "ctx": ["p1","p2"] puts contexts side by side
//   {"record": "out.webm"}                start recording (.webm or .gif); "ctx": [...] side by side
//   {"stopRecord": true}                  stop and encode the recording
// "ctx" on any other step switches context first. Strings may use ${name}.
import { spawn, spawnSync } from "node:child_process"
import { mkdtempSync, readFileSync, writeFileSync, mkdirSync, rmSync, existsSync } from "node:fs"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const die = (msg) => { console.error(`claude-shot: ${msg}`); process.exit(1) }
const log = (msg) => console.error(`  ${msg}`)

// ---------------------------------------------------------------- arguments
function parseArgs(argv) {
  const config = { base: process.env.CLAUDE_SHOT_BASE || "http://localhost:3017", size: "1280x900", full: false, settle: 300, vars: {} }
  const steps = []
  const positional = []
  const xy = (v) => v.split(",").map(Number)
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    const next = () => { if (i + 1 >= argv.length) die(`${a} needs a value`); return argv[++i] }
    switch (a) {
      case "-h": case "--help": usage(); process.exit(0)
      case "--script": Object.assign(config, JSON.parse(readFileSync(next(), "utf8")), { fromScript: true }); break
      case "--base": config.base = next(); break
      case "--color-scheme": steps.push({ colorScheme: next() }); break
      case "--size": steps.length ? steps.push({ size: next() }) : (config.size = next()); break
      case "--full": config.full = true; break
      case "--settle": config.settle = Number(next()); break
      case "--var": { const [k, ...v] = next().split("="); config.vars[k] = v.join("="); break }
      case "--ctx": steps.push({ ctx: next() }); break
      case "--goto": steps.push({ goto: next() }); break
      case "--click": steps.push({ click: next() }); break
      case "--click-at": steps.push({ clickAt: xy(next()) }); break
      case "--fill": { const [sel, ...v] = next().split("="); steps.push({ fill: sel, text: v.join("=") }); break }
      case "--eval": steps.push({ eval: next() }); break
      case "--wait": steps.push({ wait: Number(next()) }); break
      case "--key": steps.push({ key: next() }); break
      case "--type": steps.push({ type: next() }); break
      case "--wait-for": steps.push({ waitFor: next() }); break
      case "--scroll": steps.push({ scroll: xy(next()) }); break
      case "--shot": steps.push({ shot: next() }); break
      case "--record": steps.push({ record: next() }); break
      case "--stop-record": steps.push({ stopRecord: true }); break
      default:
        if (a.startsWith("-")) die(`unknown flag ${a} (try --help)`)
        positional.push(a)
    }
  }
  if (config.fromScript) {
    config.steps = [...(config.steps || []), ...steps]
  } else {
    const [url, out] = positional
    if (!url) { usage(); process.exit(1) }
    // claude-shot URL OUT [steps...]: load URL, run the steps, then save OUT.
    config.steps = [{ goto: url }, ...steps]
    if (out) config.steps.push({ shot: out })
    else if (!steps.some((s) => s.shot)) config.steps.push({ shot: "shot.png" })
  }
  return config
}

function usage() {
  console.error(`usage: bin/claude-shot URL [OUT.png] [--size WxH] [--full] [steps...]
       bin/claude-shot --script flow.json [--var name=value]

steps (run in order, after URL loads):
  --click SEL  --click-at X,Y  --fill SEL=TEXT  --key KEY  --type TEXT  --eval JS  --wait MS  --wait-for SEL
  --scroll X,Y  --size WxH  --color-scheme dark|light  --ctx NAME  --goto URL  --shot FILE  --record FILE.webm|gif  --stop-record
options: --base URL (default http://localhost:3017)  --settle MS (pause after load, default 300)
See doc/changelog/README.md for the JSON format and examples.`)
}

// ---------------------------------------------------------------- browser
function which(cmd) { return spawnSync("sh", ["-c", `command -v ${cmd}`]).status === 0 }

async function launchBrowser() {
  const bin = process.env.CHROMIUM || ["chromium", "chromium-browser", "google-chrome"].find(which)
  if (!bin) die("chromium not found (set CHROMIUM=/path/to/chrome)")
  const profile = mkdtempSync(join(tmpdir(), "claude-shot-"))
  const proc = spawn(bin, ["--headless=new", "--disable-gpu", "--hide-scrollbars", "--mute-audio",
    "--no-first-run", "--no-default-browser-check", "--remote-debugging-port=0",
    `--user-data-dir=${profile}`, "about:blank"], { stdio: "ignore" })
  const portFile = join(profile, "DevToolsActivePort")
  for (let i = 0; i < 100 && !existsSync(portFile); i++) await sleep(100)
  if (!existsSync(portFile)) die("chromium did not start")
  const [port, path] = readFileSync(portFile, "utf8").trim().split("\n")
  const ws = new WebSocket(`ws://127.0.0.1:${port}${path}`)
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej })
  const cleanup = () => { try { ws.close() } catch {} ; proc.kill(); setTimeout(() => rmSync(profile, { recursive: true, force: true }), 300) }
  return { ws, cleanup }
}

class CDP {
  constructor(ws) {
    this.ws = ws; this.nextId = 1; this.pending = new Map(); this.listeners = []
    ws.onmessage = (m) => {
      const msg = JSON.parse(m.data)
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject, method } = this.pending.get(msg.id)
        this.pending.delete(msg.id)
        msg.error ? reject(new Error(`${method}: ${msg.error.message}`)) : resolve(msg.result)
      } else {
        for (const l of this.listeners) l(msg)
      }
    }
  }
  send(method, params = {}, sessionId) {
    const id = this.nextId++
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, method })
      this.ws.send(JSON.stringify({ id, method, params, ...(sessionId && { sessionId }) }))
    })
  }
  on(fn) { this.listeners.push(fn) }
  once(sessionId, method, timeout = 15000) {
    return new Promise((resolve) => {
      const l = (msg) => { if (msg.sessionId === sessionId && msg.method === method) { this.listeners.splice(this.listeners.indexOf(l), 1); resolve(msg.params) } }
      this.listeners.push(l)
      setTimeout(() => resolve(null), timeout)
    })
  }
}

// key: [code, keyCode, text]
const KEYS = { Escape: ["Escape", 27], Enter: ["Enter", 13, "\r"], Tab: ["Tab", 9], Backspace: ["Backspace", 8] }

// One isolated browser context (own cookies/storage) with a single page.
class Context {
  static async create(cdp, name, size) {
    const { browserContextId } = await cdp.send("Target.createBrowserContext", { disposeOnDetach: true })
    const { targetId } = await cdp.send("Target.createTarget", { url: "about:blank", browserContextId })
    const { sessionId } = await cdp.send("Target.attachToTarget", { targetId, flatten: true })
    const ctx = new Context(cdp, name, sessionId)
    for (const d of ["Page", "Runtime", "Log"]) await ctx.send(`${d}.enable`)
    await ctx.setSize(size)
    cdp.on((msg) => { if (msg.sessionId === sessionId) ctx.onEvent(msg) })
    return ctx
  }
  constructor(cdp, name, sessionId) { Object.assign(this, { cdp, name, sessionId, problems: [] }) }
  send(method, params) { return this.cdp.send(method, params, this.sessionId) }
  onEvent({ method, params }) {
    if (method === "Runtime.exceptionThrown") this.problems.push(params.exceptionDetails.exception?.description || params.exceptionDetails.text)
    if (method === "Runtime.consoleAPICalled" && params.type === "error") this.problems.push(`console.error: ${params.args.map((a) => a.value ?? a.description).join(" ")}`)
    if (method === "Log.entryAdded" && params.entry.level === "error") this.problems.push(`${params.entry.text} ${params.entry.url || ""}`.trim())
    if (method === "Page.screencastFrame") this.recorder?.frame(params)
  }
  async setSize(size) {
    const [width, height] = String(size).split("x").map(Number)
    if (!width || !height) die(`bad size ${size} (want WxH)`)
    this.width = width; this.height = height
    await this.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: width < 600 })
    if (width < 600) await this.send("Emulation.setTouchEmulationEnabled", { enabled: false })
  }
  async eval(expression) {
    const r = await this.send("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true, userGesture: true })
    if (r.exceptionDetails) throw new Error(`eval failed: ${r.exceptionDetails.exception?.description || r.exceptionDetails.text}`)
    return r.result.value
  }
  async goto(url, settle) {
    const loaded = this.cdp.once(this.sessionId, "Page.loadEventFired")
    const r = await this.send("Page.navigate", { url })
    if (r.errorText) throw new Error(`goto ${url}: ${r.errorText}`)
    await loaded
    await this.eval("document.fonts && document.fonts.ready.then(() => true)").catch(() => {})
    await this.loadImages()
    await sleep(settle)
  }
  // Lazy images would otherwise stay empty in full-page shots and shift the
  // layout under scroll steps, so load them all up front.
  loadImages() {
    return this.eval(`Promise.all([...document.images].map((img) => { img.loading = "eager";
      return img.complete ? null : new Promise((r) => { img.onload = img.onerror = r; setTimeout(r, 5000) }) }))`).catch(() => {})
  }
  async mouseClick(x, y) {
    for (const type of ["mouseMoved", "mousePressed", "mouseReleased"])
      await this.send("Input.dispatchMouseEvent", { type, x, y, button: type === "mouseMoved" ? "none" : "left", clickCount: 1 })
  }
  async click(selector) {
    const r = await this.eval(`(() => { const el = document.querySelector(${JSON.stringify(selector)}); if (!el) return null;
      el.scrollIntoView({ block: "center", inline: "center" }); const b = el.getBoundingClientRect();
      return { x: b.x + b.width / 2, y: b.y + b.height / 2 } })()`)
    if (!r) throw new Error(`click: no element matches ${selector}`)
    await this.mouseClick(r.x, r.y)
  }
  async key(key) {
    const [code, keyCode, text] = KEYS[key] || [`Key${key.toUpperCase()}`, key.toUpperCase().charCodeAt(0), key]
    const base = { key, code, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode }
    await this.send("Input.dispatchKeyEvent", { type: text ? "keyDown" : "rawKeyDown", ...base, ...(text ? { text } : {}) })
    await this.send("Input.dispatchKeyEvent", { type: "keyUp", ...base })
  }
  async waitFor(selector, timeout = 10000) {
    const start = Date.now()
    while (Date.now() - start < timeout) {
      if (await this.eval(`!!document.querySelector(${JSON.stringify(selector)})`).catch(() => false)) return
      await sleep(100)
    }
    throw new Error(`waitFor: ${selector} did not appear within ${timeout}ms`)
  }
  async screenshot(full) {
    const params = { format: "png" }
    if (full) {
      await this.loadImages()
      const m = await this.send("Page.getLayoutMetrics")
      const { width, height } = m.cssContentSize || m.contentSize
      params.captureBeyondViewport = true
      params.clip = { x: 0, y: 0, width: Math.max(width, this.width), height: Math.max(height, this.height), scale: 1 }
    }
    return Buffer.from((await this.send("Page.captureScreenshot", params)).data, "base64")
  }
}

// ---------------------------------------------------------------- recording
class Recorder {
  constructor(ctx, dir, t0) { Object.assign(this, { ctx, dir, t0, frames: [] }); mkdirSync(dir, { recursive: true }) }
  async start() {
    this.ctx.recorder = this
    await this.ctx.send("Page.startScreencast", { format: "jpeg", quality: 85, maxWidth: this.ctx.width, maxHeight: this.ctx.height, everyNthFrame: 1 })
  }
  frame({ data, sessionId }) {
    const file = join(this.dir, `f${String(this.frames.length).padStart(5, "0")}.jpg`)
    writeFileSync(file, Buffer.from(data, "base64"))
    this.frames.push({ file, t: (Date.now() - this.t0) / 1000 })
    this.ctx.send("Page.screencastFrameAck", { sessionId }).catch(() => {})
  }
  async stop(tEnd) {
    await this.ctx.send("Page.stopScreencast"); this.ctx.recorder = null
    if (!this.frames.length) throw new Error(`recording ${this.ctx.name}: no frames captured`)
    // ffconcat list: each frame lasts until the next one; the first one is
    // stretched back to t=0 so side-by-side recordings stay in sync.
    const lines = ["ffconcat version 1.0"]
    this.frames.forEach((f, i) => {
      const end = i + 1 < this.frames.length ? this.frames[i + 1].t : tEnd
      lines.push(`file '${f.file}'`, `duration ${Math.max(end - (i ? f.t : 0), 0.001).toFixed(3)}`)
    })
    lines.push(`file '${this.frames.at(-1).file}'`)
    const list = join(this.dir, "frames.ffconcat")
    writeFileSync(list, lines.join("\n") + "\n")
    return list
  }
}

function ffmpeg(args) {
  const [cmd, pre] = which("ffmpeg") ? ["ffmpeg", []] : ["nix", ["shell", "nixpkgs#ffmpeg", "-c", "ffmpeg"]]
  const r = spawnSync(cmd, [...pre, "-hide_banner", "-loglevel", "error", "-y", ...args], { stdio: ["ignore", "inherit", "inherit"] })
  if (r.status !== 0) throw new Error("ffmpeg failed")
}

function encode(lists, out, fps) {
  const inputs = lists.flatMap((l) => ["-f", "concat", "-safe", "0", "-i", l])
  // Constant frame rate, even dimensions, then (for several contexts) side by side with a 16px gap.
  const norm = lists.map((_, i) => `[${i}:v]fps=${fps},pad=ceil(iw/2)*2:ceil(ih/2)*2[v${i}]`).join(";")
  const layout = lists.map((_, i) => i ? `${lists.slice(0, i).map((__, j) => `w${j}`).join("+")}+${16 * i}_0` : "0_0").join("|")
  const vf = lists.length > 1
    ? `${norm};${lists.map((_, i) => `[v${i}]`).join("")}xstack=inputs=${lists.length}:layout=${layout}:fill=0x888888,pad=ceil(iw/2)*2:ceil(ih/2)*2`
    : `${norm};[v0]null`
  if (out.endsWith(".gif")) {
    ffmpeg([...inputs, "-filter_complex", `${vf},split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4`, out])
  } else if (out.endsWith(".webm")) {
    ffmpeg([...inputs, "-filter_complex", vf, "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "36", "-row-mt", "1", "-deadline", "good", "-cpu-used", "4", "-pix_fmt", "yuv420p", "-an", out])
  } else if (out.endsWith(".mp4")) {
    ffmpeg([...inputs, "-filter_complex", vf, "-c:v", "libx264", "-crf", "26", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", out])
  } else {
    throw new Error(`record: ${out} must end in .webm, .gif or .mp4`)
  }
}

// ---------------------------------------------------------------- main
async function main() {
  const config = parseArgs(process.argv.slice(2))
  const vars = { ...(config.vars || {}) }
  const interp = (v) => typeof v === "string" ? v.replace(/\$\{(\w+)\}/g, (_, k) => k in vars ? vars[k] : die(`unknown variable \${${k}}`)) : v
  const urlFor = (u) => new URL(interp(u), config.base.replace(/\/?$/, "/")).toString()
  const outPath = (f) => { const p = resolve(interp(f)); mkdirSync(dirname(p), { recursive: true }); return p }

  const { ws, cleanup } = await launchBrowser()
  process.on("exit", cleanup)
  const cdp = new CDP(ws)
  const contexts = new Map()
  let current = null
  const ctxNamed = async (name) => {
    if (!contexts.has(name)) contexts.set(name, await Context.create(cdp, name, config.size))
    return contexts.get(name)
  }
  const ctxList = (v) => Promise.all((Array.isArray(v) ? v : [v ?? current.name]).map(ctxNamed))
  current = await ctxNamed("main")
  let recording = null
  const workDir = mkdtempSync(join(tmpdir(), "claude-shot-frames-"))
  process.on("exit", () => rmSync(workDir, { recursive: true, force: true }))

  for (const [n, step] of config.steps.entries()) {
    const label = `#${n + 1} ${JSON.stringify(step)}`
    try {
      const multi = Array.isArray(step.ctx)
      if (step.ctx && !multi) current = await ctxNamed(step.ctx)
      const c = current
      if (step.goto) await c.goto(urlFor(step.goto), step.settle ?? config.settle)
      else if (step.click) await c.click(interp(step.click))
      else if (step.clickAt) { const [x, y] = Array.isArray(step.clickAt) ? step.clickAt : step.clickAt.split(",").map(Number); await c.mouseClick(x, y) }
      else if (step.fill) await c.eval(`(() => { const el = document.querySelector(${JSON.stringify(interp(step.fill))}); if (!el) throw new Error("fill: no element");
          el.focus(); el.value = ${JSON.stringify(interp(step.text ?? ""))};
          el.dispatchEvent(new Event("input", { bubbles: true })); el.dispatchEvent(new Event("change", { bubbles: true })) })()`)
      else if (step.eval) { const v = await c.eval(interp(step.eval)); if (step.as) vars[step.as] = v; if (v !== undefined) log(`${c.name}: ${JSON.stringify(v)}`) }
      else if (step.key) await c.key(interp(step.key))
      else if (step.type) await c.send("Input.insertText", { text: interp(step.type) })
      else if (step.grant) {
        const origin = new URL(await c.eval("location.href")).origin
        const { browserContextId } = (await c.send("Target.getTargetInfo")).targetInfo
        await cdp.send("Browser.grantPermissions", { permissions: [].concat(step.grant), origin, browserContextId })
      }
      else if (step.wait) await sleep(step.wait)
      else if (step.waitFor) await c.waitFor(interp(step.waitFor), step.timeout)
      else if (step.scroll) { const [x, y] = Array.isArray(step.scroll) ? step.scroll : step.scroll.split(",").map(Number); await c.eval(`window.scrollTo(${x}, ${y})`); await sleep(150) }
      else if (step.size) await c.setSize(step.size)
      else if (step.colorScheme) { await c.send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: step.colorScheme }] }); await sleep(100) }
      else if (step.shot) {
        const out = outPath(step.shot)
        const full = step.full ?? config.full
        const targets = multi ? await ctxList(step.ctx) : [c]
        const pngs = await Promise.all(targets.map((t) => t.screenshot(full)))
        if (pngs.length === 1) writeFileSync(out, pngs[0])
        else writeFileSync(out, await sideBySide(await ctxNamed("__compose"), pngs, step.label !== false ? targets.map((t) => t.name) : null))
        log(`saved ${out}`)
      } else if (step.record) {
        if (recording) throw new Error("already recording; add a stopRecord step first")
        const targets = multi ? await ctxList(step.ctx) : [c]
        const t0 = Date.now()
        recording = { out: outPath(step.record), fps: step.fps || 15, recorders: targets.map((t) => new Recorder(t, join(workDir, `${n}-${t.name}`), t0)) }
        for (const r of recording.recorders) await r.start()
      } else if (step.stopRecord) {
        if (!recording) throw new Error("not recording")
        await sleep(200)
        const tEnd = (Date.now() - recording.recorders[0].t0) / 1000
        const lists = []
        for (const r of recording.recorders) lists.push(await r.stop(tEnd))
        encode(lists, recording.out, recording.fps)
        log(`saved ${recording.out} (${tEnd.toFixed(1)}s)`)
        recording = null
      } else if (!step.ctx) throw new Error("unknown step")
    } catch (e) {
      console.error(`claude-shot: step ${label} failed: ${e.message}`)
      process.exitCode = 1
      break
    }
  }
  if (recording && !process.exitCode) console.error("claude-shot: warning: recording was never stopped (add a stopRecord step)")
  for (const c of contexts.values()) for (const p of c.problems) console.error(`  page error (${c.name}): ${p}`)
  if (Object.keys(vars).length && config.printVars) console.log(JSON.stringify(vars))
}

// Lay out PNGs side by side (with context names as labels) in a scratch page.
async function sideBySide(ctx, pngs, labels) {
  const imgs = pngs.map((b, i) => `<figure><img src="data:image/png;base64,${b.toString("base64")}">${labels ? `<figcaption>${labels[i]}</figcaption>` : ""}</figure>`).join("")
  const html = `<!doctype html><style>body{margin:0;background:#888;font:600 14px sans-serif;color:#fff}
    main{display:inline-flex;gap:16px;align-items:flex-start;padding:16px}figure{margin:0}img{display:block;box-shadow:0 2px 10px #0006}
    figcaption{margin-top:6px;text-align:center}</style><main>${imgs}</main>`
  await ctx.setSize("400x300")
  const { frameTree } = await ctx.send("Page.getFrameTree")
  await ctx.send("Page.setDocumentContent", { frameId: frameTree.frame.id, html })
  await ctx.eval("Promise.all([...document.images].map(i => i.decode()))")
  const box = await ctx.eval("(() => { const r = document.querySelector('main').getBoundingClientRect(); return { width: Math.ceil(r.width), height: Math.ceil(r.height) } })()")
  return Buffer.from((await ctx.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true, clip: { x: 0, y: 0, ...box, scale: 1 } })).data, "base64")
}

main().then(() => process.exit(process.exitCode ?? 0), (e) => die(e.stack || e.message))
