# Yiji Focus Float

Yiji Focus Float is a local-first ADHD task companion where Yiji becomes a tiny desktop cheerleader for your day.

The core loop is intentionally simple:

1. Double-click Yiji.
2. Pick one preset task category.
3. Let the timer run quietly in the background.
4. Double-click Yiji again to end the block.
5. Watch your day turn into a visible schedule of real effort.

## Why this exists

Many task tools try to sync across phone and laptop. This one does the opposite on purpose.

Yiji Focus Float is designed to live only on your computer, stay emotionally lightweight, and make progress feel tangible instead of bureaucratic.

## What works now

- Yiji-style floating button using the custom pet art
- Preset task categories: `读文献`, `洗数据`, `做模型`, `写论文`, `娱乐`, `饭饭`, `运动`, `家庭生活`
- Double-click to start, double-click to stop
- Automatic timestamps for every task block
- Closeout notes for outcome and feelings
- A daily schedule view with color-coded blocks
- Daily summary cards for count, total minutes, and longest block
- Encouragement feedback from Yiji
- A lightweight weekly report
- Quiet reminder logic that only nudges when no task is active and the computer appears idle
- Local-only browser storage plus JSON export

## Current limitation

This prototype does **not yet** hook into the real Codex pet double-click event.

Right now, the interaction is implemented inside the prototype UI itself as a stand-in for future native pet integration.

So today the architecture is:

- `Prototype now`: double-click the Yiji button inside the float
- `Future upgrade`: connect the same logic to a real pet event if Codex exposes one

## Run locally

From the repo root:

```bash
node ./plugins/yiji-focus-float/scripts/serve.mjs
```

Then open:

```text
http://127.0.0.1:4318
```

## Project structure

- `prototype/`: the current local web prototype
- `prototype/assets/`: Yiji button art
- `scripts/serve.mjs`: tiny local static server
- `.codex-plugin/plugin.json`: local plugin scaffold

## License

MIT

## Next ideas

- real pet trigger if Codex exposes double-click hooks
- slimmer always-on-top desktop shell
- app-level idle detection outside the browser sandbox
- richer weekly trends once the daily loop feels stable
