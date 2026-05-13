# Yiji Focus Float

Yiji Focus Float turns Yiji into a tiny local-first ADHD task companion for macOS.

The loop is intentionally lightweight:

1. Double-click Yiji.
2. Pick one preset category.
3. Let the timer run quietly.
4. Double-click again to wrap up.
5. Watch `Done Today` and `Done This Week` grow into a visible record of effort.

## What works now

- Native macOS floating pet app
- Drag-to-place Yiji overlay that stays above normal windows
- Preset categories:
  `开组会`, `seminar`, `读文献`, `洗数据`, `做模型`, `写论文`, `娱乐`, `饭饭`, `运动`, `家庭生活`
- Double-click to start and stop a block
- Single-click to open `Done Today` and `Done This Week`
- Right-click menu with `Quit`
- Automatic timestamps for each block
- Closeout notes for outcome and feelings
- Calendar-like review panel with color blocks
- Quiet reminders only when no task is active and the machine appears idle
- Extra reminder if `娱乐` runs past one hour
- Local-only storage using `NSUserDefaults`

## Current pet copy

- Start title: `喵，离accept更进一步`
- Start encouragement: `喵，努力给咪挣罐罐鸭！`
- Finish button: `喵，人好棒！`
- Quit line: `喵，退下吧人。`
- Idle reminder: `喵，人在干什么？`
- Entertainment reminder: `喵，不是说好要带咪发AER的吗？`

## Build the app

From the repo root:

```bash
./plugins/yiji-focus-float/scripts/build-app.sh
```

This builds:

```text
plugins/yiji-focus-float/dist/Yiji Focus Float.app
```

## Run for testing

From the repo root:

```bash
./plugins/yiji-focus-float/scripts/run-desktop.sh
```

## Share kit

Friend-facing guide images live here:

- `plugins/yiji-focus-float/share-kit/chapter-01-start.png`
- `plugins/yiji-focus-float/share-kit/chapter-02-reminders.png`
- `plugins/yiji-focus-float/share-kit/chapter-03-wrapup-and-today.png`
- `plugins/yiji-focus-float/share-kit/chapter-04-today-week.png`
- `plugins/yiji-focus-float/share-kit/yiji-guide-long.png`

To regenerate them:

```bash
"/Users/jingyuanwang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3" ./plugins/yiji-focus-float/scripts/make_share_kit.py
```

## Project structure

- `desktop/`: native macOS app code
- `prototype/`: earlier browser prototype and assets
- `prototype/assets/`: pet art
- `prototype/motions/`: motion frame folders
- `scripts/build-app.sh`: build the `.app`
- `scripts/run-desktop.sh`: build and launch for testing
- `scripts/make_share_kit.py`: generate the four guide images and long poster

## Customize it

### Change the task list

Edit:

- `plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

Search for:

- `self.categories = @[`

If you also want the old browser prototype to match, update:

- `plugins/yiji-focus-float/prototype/app.js`

### Change Yiji's lines

Edit:

- `plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

Useful search targets:

- `喵，离accept更进一步`
- `喵，努力给咪挣罐罐鸭！`
- `喵，人好棒！`
- `喵，退下吧人。`
- `喵，人在干什么？`
- `喵，不是说好要带咪发AER的吗？`

### Change the pet art or motion

The desktop app currently uses:

- `plugins/yiji-focus-float/prototype/assets/yiji-static-final.png`
- `plugins/yiji-focus-float/prototype/motions/idle/`
- `plugins/yiji-focus-float/prototype/motions/running/`
- `plugins/yiji-focus-float/prototype/motions/jumping/`
- `plugins/yiji-focus-float/prototype/motions/waving/`

Current behavior:

- `idle`: still pose
- `running`: brief energetic motion when a task starts
- `jumping`: happy motion when a task ends
- `waving`: goodbye motion on quit

## Platform note

This desktop app is currently `macOS only`.

## License

MIT
