# strict-ime.nvim

A Neovim plugin for Linux + Fcitx5 that keeps Normal/Visual/Select/Operator-pending modes in English and switches back to your configured input method when entering Insert mode.

It is designed to work on Omarchy and standard Arch installations without depending on `pysan3/fcitx5.nvim`.

## Features

- Works with terminal Neovim and GUI Neovim clients.
- Uses Fcitx5 D-Bus through a persistent helper process when available.
- Falls back to `fcitx5-remote` if the helper is not installed.
- Can be loaded with `lazy.nvim` through a single plugin specification.
- Does not depend on a particular Neovim configuration or plugin manager.

## Requirements

- Linux
- Fcitx5
- `fcitx5-remote` on `PATH` for the fallback mode
- Neovim 0.9 or newer for `vim.system`/`vim.uv` support

On Omarchy, Fcitx5 is already installed. Install a Chinese engine separately, for example:

```bash
omarchy pkg add fcitx5-chinese-addons fcitx5-configtool
```

## Installation

Add this to `lua/plugins/strict-ime.lua`:

```lua
return {
  {
    "vvinnpy/strict-ime.nvim",
    lazy = false,
    opts = {
      english = "keyboard-us",
      insert = "pinyin",
      poll_interval = 200,
    },
    -- Optional: download the prebuilt D-Bus helper for this Linux architecture.
    build = function()
      require("strict-ime.install").install()
    end,
  },
}
```

Replace `pysan3/fcitx5.nvim` if it is present. Do not run both plugins with their own `ModeChanged` autocmds enabled. Omarchy ships LazyVim but does not include `pysan3/fcitx5.nvim` by default.

## Configuration

```lua
require("strict-ime").setup({
  english = "keyboard-us",
  insert = "pinyin",
  imname = {
    norm = "keyboard-us",
    ins = "pinyin",
    cmd = "keyboard-us",
    vis = "keyboard-us",
    sel = "keyboard-us",
    opr = "keyboard-us",
    term = nil,
    lang = nil,
  },
  strict_modes = {
    norm = true,
    opr = true,
    vis = true,
    sel = true,
    cmd = true,
  },
  remember_prior = true,
  autostart_fcitx5 = true,
  poll_interval = 200,
  helper = {
    enabled = true,
    path = nil,
    repo = "vvinnpy/strict-ime.nvim",
  },
})
```

- `english`: fallback English input method.
- `insert`: fallback input method for Insert mode.
- `imname`: per-mode input method, compatible with the old `fcitx5.nvim` model.
- `strict_modes`: modes where manual switching is forced back to English.
- `remember_prior`: remember the input method used in each mode.
- `autostart_fcitx5`: start Fcitx5 if it is not already running.
- `legacy_commands`: expose `Fcitx5*` compatibility commands.
- `poll_interval`: D-Bus status check interval, in milliseconds.
- `helper.enabled`: use the persistent helper when available.
- `helper.path`: optional explicit helper path.

## Commands

- `:StrictImeInstallHelper` downloads the matching Linux helper from the latest GitHub Release.
- `:StrictImeRestart` restarts the helper and reloads mode state.
- `:StrictImeStatus` shows the current mode, helper state, and strict state.
- `:StrictImeSetName <imname>` forces an input method for the current mode.
- `:StrictImeGeneious` reapplies the current mode configuration.
- `:StrictImeOnModeChanged` compatibility entry point for `ModeChanged`.
- `:StrictImeSetPrior <imname> [mode]` sets the remembered input method.
- `:StrictImeGetImname [mode]` prints the input method for a mode.
- `:StrictImeGetImnames` prints all mode input methods.

When `legacy_commands` is enabled, the following aliases are also available:
`Fcitx5`, `Fcitx5SetName`, `Fcitx5Geneious`, `Fcitx5OnModeChanged`,
`Fcitx5SetPrior`, `Fcitx5GetImname`, and `Fcitx5GetImnames`.

## Compatibility

Existing configurations that call `require("fcitx5").setup({...})` can keep that API while using this repository. The compatibility module maps the old setup options and `Fcitx5*` functions to `strict-ime`.

## Performance

The helper maintains one Fcitx5 D-Bus connection and checks `State()` only while strict mode is active. It does not spawn a process on every poll.

The Lua fallback starts only when the helper is unavailable. It uses `fcitx5-remote` and therefore spawns a process at the configured interval while strict mode is active.

## License

MIT
