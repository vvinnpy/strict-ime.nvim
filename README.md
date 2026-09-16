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
  poll_interval = 200,
  auto_start = true,
  helper = {
    enabled = true,
    path = nil,
    repo = "vvinnpy/strict-ime.nvim",
  },
})
```

- `english`: input method to use in strict modes.
- `insert`: input method to use when entering Insert mode.
- `poll_interval`: D-Bus status check interval, in milliseconds.
- `helper.enabled`: use the persistent helper when available.
- `helper.path`: optional explicit helper path.

## Commands

- `:StrictImeInstallHelper` downloads the matching Linux helper from the latest GitHub Release.
- `:StrictImeRestart` restarts the helper and reloads mode state.
- `:StrictImeStatus` shows the current mode, helper state, and fallback state.

## Performance

The helper maintains one Fcitx5 D-Bus connection and checks `State()` only while strict mode is active. It does not spawn a process on every poll.

The Lua fallback starts only when the helper is unavailable. It uses `fcitx5-remote` and therefore spawns a process at the configured interval while strict mode is active.

## License

MIT
