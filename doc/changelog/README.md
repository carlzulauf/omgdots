# Changelog and screenshots

Every requested change is tracked in `changelog.yml` and shown on the
development-only page <http://localhost:3017/changelog>. The routes are drawn
only in development (`config/routes.rb`), and `ChangelogController` returns 404
in any other environment as a backstop.

## Dev environment

The app runs on **port 3017** (port 3000 belongs to another app). Use
`nix develop -c <cmd>` for anything that needs Ruby.

```sh
nix develop -c bin/dev          # redis + web (3017) + dartsass:watch via foreman
```

When it runs detached in the `omgdots` tmux session (windows `redis`, `web`,
`css`), always pass an explicit `-t omgdots...` target, since other tmux
sessions exist:

```sh
curl -s -o /dev/null -w '%{http_code}\n' localhost:3017/changelog   # is it up?
tmux list-windows -t omgdots
tmux capture-pane -p -t omgdots:web | tail -20                       # web log
tmux respawn-window -k -t omgdots:web                                 # restart web
tmux kill-session -t omgdots                                          # stop everything
```

To start the session from scratch (from the repo root):

```sh
tmux new-session -d -s omgdots -n redis -c "$PWD" 'nix develop -c sh -c "cd db && exec redis-server --bind 127.0.0.1 ::1"'
tmux new-window -d -t omgdots -n web -c "$PWD" 'nix develop -c bin/rails server -p 3017'
tmux new-window -d -t omgdots -n css -c "$PWD" 'nix develop -c bin/rails dartsass:watch'
```

Specs: `nix develop -c bundle exec rspec`. `spec/models/changelog_spec.rb` checks
that `changelog.yml` loads and that every media file it lists exists.

## bin/claude-shot

`bin/claude-shot` drives headless Chromium over the DevTools protocol
(`script/claude/shot.mjs`). It uses the host's `node` (22+), or falls back to
`nix shell nixpkgs#nodejs`. Node is intentionally not in the app's flake.
Relative URLs resolve against `http://localhost:3017` (`--base` changes it).
Page errors (exceptions, console errors, failed requests) are printed at the
end, and a failed step exits 1.

```sh
# Viewport screenshot (1280x900 by default)
bin/claude-shot /changelog doc/changelog/media/001-changelog-desktop.png

# Phone size, full page
bin/claude-shot /changelog tmp/phone.png --size 375x667 --full

# Dark mode
bin/claude-shot /changelog tmp/dark.png --color-scheme dark

# Steps run in order after the page loads, then OUT is saved
bin/claude-shot /games/demo tmp/p1.png \
  --wait-for '.board' --click '.player-1-link' --wait 500 \
  --click-at 340,250 --eval 'document.title' --scroll 0,400

# Several shots in one run
bin/claude-shot /changelog --shot tmp/top.png --scroll 0,1500 --shot tmp/lower.png

# Recording (.webm, .gif or .mp4) of the steps between --record and --stop-record
bin/claude-shot /changelog tmp/end.png --size 375x667 \
  --record tmp/scroll.webm --scroll 0,800 --wait 500 --scroll 0,1600 --wait 500 --stop-record
```

Flags: `--click SEL`, `--click-at X,Y`, `--fill SEL=TEXT`, `--key KEY` (Escape,
Enter, Tab, Backspace or one character), `--type TEXT` (into the focused
element), `--eval JS`,
`--wait MS`, `--wait-for SEL`, `--scroll X,Y`, `--size WxH`,
`--color-scheme dark|light`, `--goto URL`, `--ctx NAME`, `--shot FILE`,
`--record FILE`, `--stop-record`, `--full`, `--settle MS` (pause after each
load, default 300).

### Two players (two browser contexts) from a JSON script

Each context has its own cookies, so it is a separate player. A step with a
`ctx` name switches to that context (creating it if needed), and later steps
stay there. With a list (`"ctx": ["player1", "player2"]`), `shot` and `record`
put the contexts side by side. `${name}` is replaced by `--var name=value` or
by an earlier `{"eval": ..., "as": "name"}`.

```json
{
  "size": "640x720",
  "steps": [
    {"ctx": "player1", "goto": "/games/${game}"},
    {"ctx": "player2", "goto": "/games/${game}"},
    {"record": "${out}/flow.webm", "ctx": ["player1", "player2"]},
    {"ctx": "player1", "click": ".player-1-link"},
    {"wait": 600},
    {"ctx": "player2", "click": ".player-2-link"},
    {"wait": 600},
    {"ctx": "player1", "click": ".board .hline:not(.drawn)"},
    {"wait": 800},
    {"stopRecord": true},
    {"shot": "${out}/flow.png", "ctx": ["player1", "player2"]},
    {"ctx": "player2", "eval": "document.querySelectorAll('.board .drawn').length"}
  ]
}
```

```sh
bin/claude-shot --script tmp/flow.json --var game=demo$RANDOM --var out=tmp
```

JSON step keys: `goto`, `click`, `clickAt: [x, y]`, `fill` + `text`, `eval`
(+ `as`), `key`, `type`, `grant` (permissions for the current context, e.g.
`["clipboardReadWrite"]`), `wait`, `waitFor` (+ `timeout`), `scroll: [x, y]`, `size`,
`colorScheme`, `shot` (+ `full`), `record` (+ `fps`, default 15),
`stopRecord`, `ctx`. Top-level keys: `base`, `size`, `full`, `settle`, `vars`.
Recordings come from `Page.startScreencast` frames, encoded with `ffmpeg`
(the host's, or `nix shell nixpkgs#ffmpeg`).

## changelog.yml

```yaml
entries:
  - id: 1                    # unique, never reused
    title: "Short title"
    status: queued           # queued | in_progress | blocked | done | dropped
    priority: 2              # 1 = highest
    requested: "2026-11-13"  # quote dates
    completed: null          # "YYYY-MM-DD" once done
    blocked_by: []           # entry ids, shown as links in the queue
    request: "The user's words, close to verbatim"
    summary: |
      A short paragraph, and/or bullets:
      - one per line, starting with "- "
      - `backticks` become code
    commits: [abc1234]
    media:
      - file: "001-changelog-desktop.png"
        caption: "The changelog page"
```

The page shows the **Queue** (in progress, then queued, then blocked, each by
priority then id), **Done** (newest `completed` first, with request, summary,
commits and media) and **Dropped** (collapsed).

Media lives in `doc/changelog/media/`, named `NNN-description.ext`, where NNN
is the entry id zero-padded to 3 digits (`004-status-bar-phone.png`). PNG and
GIF are shown as images (click for full size); WebM and MP4 as muted, looping
videos. Keep files small: prefer viewport shots to very tall full-page ones,
and short recordings.
