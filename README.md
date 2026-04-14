# clack.nvim

`clack.nvim` adds mechanical keyboard sound effects to Neovim keystrokes.

## Requirements

- Neovim >= 0.10.0 (`vim.system()` is required)
- One of:
  - `afplay` (macOS)
  - `aplay` (Linux)
  - PowerShell (Windows)

## Installation

### lazy.nvim

```lua
{
  "your-user/clack.nvim",
  opts = {
    profile = "cherry_mx_blue",
    volume = 0.8,
    enabled = true,
    on_enter = true,
    on_space = true,
    on_save = true,
  },
}
```

### packer.nvim

```lua
use({
  "your-user/clack.nvim",
  config = function()
    require("clack").setup({
      profile = "cherry_mx_blue",
      volume = 0.8,
      enabled = true,
      on_enter = true,
      on_space = true,
      on_save = true,
    })
  end,
})
```

## Configuration

```lua
require("clack").setup({
  profile = "cherry_mx_blue",
  volume = 0.8,
  enabled = true,
  on_enter = true,
  on_space = true,
  on_save = true,
})
```

Available profiles:

- `cherry_mx_blue` (clicky)
- `cherry_mx_red` (linear)
- `topre` (thocky)
- `buckling_spring` (IBM Model M)

Public API:

- `require("clack").setup(opts)`
- `require("clack").enable()`
- `require("clack").disable()`
- `require("clack").toggle()`

Commands:

- `:ClackEnable`
- `:ClackDisable`
- `:ClackToggle`

## Sound assets

Sounds are resolved relative to the plugin install directory, with this convention:

```
sounds/
  blue/
    key_1.wav key_2.wav key_3.wav key_4.wav
    enter_1.wav enter_2.wav enter_3.wav enter_4.wav
    space_1.wav space_2.wav space_3.wav space_4.wav
    save_1.wav save_2.wav save_3.wav save_4.wav
  red/
  topre/
  buckling_spring/
```

Each keypress uses `InsertCharPre` and randomly picks one of four key variations for a more natural feel. Enter and Space use their own sound pools when enabled.
