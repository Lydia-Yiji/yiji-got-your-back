# yiji-got-your-back

Yiji Focus Float is a tiny local-first macOS desktop pet for ADHD-friendly task tracking.

You double-click Yiji to start a block, double-click again to wrap it up, and Yiji quietly turns your day into a visible schedule instead of a guilt machine.

![Yiji guide](plugins/yiji-focus-float/share-kit/yiji-guide-long.png)

## What it does

- Tiny draggable desktop pet that lives above your windows
- Double-click to start a preset task block
- Double-click again to end the block and save the result
- Calm reminders only when you are clearly inactive or stuck in long entertainment time
- `Done Today` and `Done This Week` views that turn your day into a color-block schedule
- All records stay local on your computer

## Current platform

This version is for `macOS` only.

The desktop pet is built as a native `.app`, not a cross-platform Electron shell, so Windows is not supported yet.

## App location

The built app lives here:

`plugins/yiji-focus-float/dist/Yiji Focus Float.app`

If you are building it from source, the main project lives here:

`plugins/yiji-focus-float/`

## Build from source

From the repo root:

```bash
./plugins/yiji-focus-float/scripts/build-app.sh
```

Then open:

`plugins/yiji-focus-float/dist/Yiji Focus Float.app`

For quick local testing:

```bash
./plugins/yiji-focus-float/scripts/run-desktop.sh
```

## Customize it

Your friends can easily make their own version.

### Change the task list

Edit:

`plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

Search for:

`self.categories = @[`

That controls the buttons shown in the start bubble.

### Change Yiji's lines

Edit:

`plugins/yiji-focus-float/desktop/YijiDesktopFloat.m`

Useful search targets:

- `喵，离accept更进一步`
- `喵，努力给咪挣罐罐鸭！`
- `喵，人好棒！`
- `喵，退下吧人。`
- `喵，人在干什么？`
- `喵，不是说好要带咪发AER的吗？`

Those control the start bubble, running encouragement, finish button, quit goodbye, idle reminder, and long-entertainment reminder.

### Change the pet art or motions

Pet art and motions live here:

- `plugins/yiji-focus-float/prototype/assets/`
- `plugins/yiji-focus-float/prototype/motions/idle/`
- `plugins/yiji-focus-float/prototype/motions/running/`
- `plugins/yiji-focus-float/prototype/motions/jumping/`
- `plugins/yiji-focus-float/prototype/motions/waving/`

Current behavior:

- `idle`: still pose
- `running`: brief energetic motion when a task starts
- `jumping`: happy motion when a task ends
- `waving`: goodbye motion when quitting

## License

MIT
