# clack.nvim

`clack.nvim` adds mechanical keyboard sound effects to Neovim keystrokes.

## Requirements

- Neovim >= 0.10.0 (`vim.system()` is required)
- For bundled single-file `.ogg` profiles:
  - `ffmpeg` to pre-extract the clip cache
- For legacy per-file `.wav` profiles, one of:
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
  profile = "cherrymx-blue-pbt",
  volume = 0.8,
  enabled = true,
  on_enter = true,
  on_space = true,
  on_save = true,
})
```

Available profiles are detected from `sounds/<folder>` and use the folder name as the profile id. Current bundled folders include:

- `cherrymx-blue-pbt`
- `cherrymx-blue-abs`
- `cherrymx-red-pbt`
- `cherrymx-red-abs`
- `cherrymx-brown-pbt`
- `cherrymx-brown-abs`
- `cherrymx-black-pbt`
- `cherrymx-black-abs`
- `topre-purple-hybrid-pbt`
- `eg-crystal-purple`
- `eg-oreo`
- `holy-pandas`
- `mxblue-travel`
- `mxblack-travel`
- `mxbrown-travel`
- `cream-travel`
- `turquoise`
- `nk-cream`

Public API:

- `require("clack").setup(opts)`
- `require("clack").set_profile(name)`
- `require("clack").enable()`
- `require("clack").disable()`
- `require("clack").toggle()`

Commands:

- `:ClackEnable`
- `:ClackDisable`
- `:ClackToggle`
- `:ClackProfile <sounds-folder>`

## Sound assets

Sounds are resolved relative to the plugin install directory. `clack.nvim` now supports both the original pool layout and `config.json` packs that slice a single `.ogg` file into per-key clips.

Pool layout:

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

Single-file layout:

```
sounds/
  cherrymx-blue-pbt/
    config.json
    sound.ogg
```

For single-file packs, the plugin reads the `defines` map from `config.json`, keeps a small variation pool for generic typing, and pre-extracts those slices to cached `.wav` files in the temp directory before normal playback starts. Because Neovim only exposes inserted characters rather than raw keyboard scan codes, save sounds reuse the generic key pool and release-only slices are ignored.
