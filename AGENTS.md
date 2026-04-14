# Agent instructions for `clack.nvim`

## Build, test, and lint commands

- **Run full test suite**
  - `make test`
- **Run a single test file**
  - `nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile tests/clack/clack_spec.lua"`
- **Lint Lua sources (same check used in CI)**
  - `stylua --check lua`

## High-level architecture

- `plugin/clack.lua` is the runtime entrypoint. It guards against double-load and registers user commands (`:ClackEnable`, `:ClackDisable`, `:ClackToggle`).
- `lua/clack/init.lua` is the orchestrator: it owns plugin state/config, exposes the public API (`setup/enable/disable/toggle`), routes events to sound pools, and manages enabled/disabled lifecycle.
- `lua/clack/events.lua` owns autocommand wiring. It creates a single augroup and binds:
  - `InsertCharPre` for per-keystroke sounds
  - `BufWritePost` for optional save sounds
- `lua/clack/profiles.lua` defines profile metadata and resolves all sound file paths relative to plugin install root via `debug.getinfo` + `vim.fn.fnamemodify`.
- `lua/clack/audio.lua` is the platform backend selector and process launcher:
  - macOS: `afplay`
  - Linux: `aplay`
  - Windows: PowerShell `System.Media.SoundPlayer`
  - playback is started via `vim.system(..., { detach = true })`.

## Key conventions in this repository

- Sound assets follow a strict pool naming convention in `sounds/<profile>/`:
  - `key_1.wav` ... `key_4.wav`
  - `enter_1.wav` ... `enter_4.wav`
  - `space_1.wav` ... `space_4.wav`
  - `save_1.wav` ... `save_4.wav`
- Enter and space are handled as dedicated sound categories (`on_enter`, `on_space`) instead of default key sounds.
- Keystroke realism comes from random selection across 4 variations per sound category.
- Invalid profile values are surfaced with `vim.notify(...)` and fallback to `cherry_mx_blue`.
- Tests run through `tests/minimal_init.lua`, which bootstraps `plenary.nvim` into runtimepath (default `/tmp/plenary.nvim`, override with `PLENARY_DIR`).
- Formatting is controlled by `.stylua.toml` (2-space indentation, max width 120, prefer double quotes).
