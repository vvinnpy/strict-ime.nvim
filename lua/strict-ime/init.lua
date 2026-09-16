local M = {}

local config = require("strict-ime.config")
local helper = require("strict-ime.helper")
local fallback = require("strict-ime.fallback")
local mode = require("strict-ime.mode")
local install = require("strict-ime.install")

local started = false
local last_strict

local function sync_mode()
  if not started then
    return
  end

  local current = mode.current()
  if current.strict ~= last_strict then
    last_strict = current.strict
    if helper.active() then
      helper.set_strict(current.strict)
    else
      fallback.set_strict(current.strict)
    end
  end

  if not current.strict then
    local imname = config.values.insert
    if helper.active() then
      helper.set_im(imname, true)
    else
      fallback.set_im(imname, true)
    end
  end
end

local function restart_helper()
  helper.stop()
  if helper.start() then
    fallback.stop()
    helper.set_strict(mode.current().strict)
  else
    fallback.set_strict(true)
  end
  sync_mode()
end

function M.setup(opts)
  config.setup(opts)
  fallback.stop()
  helper.stop()
  last_strict = nil

  local group = vim.api.nvim_create_augroup("StrictImeNvim", { clear = true })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:*",
    callback = function()
      vim.schedule(sync_mode)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      helper.stop()
      fallback.stop()
    end,
  })

  vim.api.nvim_create_user_command("StrictImeInstallHelper", function()
    install.install()
  end, { desc = "Install the strict-ime D-Bus helper" })

  vim.api.nvim_create_user_command("StrictImeRestart", function()
    restart_helper()
    vim.notify("strict-ime: restarted", vim.log.levels.INFO)
  end, { desc = "Restart the strict-ime helper" })

  vim.api.nvim_create_user_command("StrictImeStatus", function()
    local current = mode.current()
    vim.notify(
      string.format(
        "strict-ime: mode=%s strict=%s helper=%s",
        current.mode,
        tostring(current.strict),
        tostring(helper.active())
      ),
      vim.log.levels.INFO
    )
  end, { desc = "Show strict-ime status" })

  started = true
  if config.values.auto_start then
    restart_helper()
  end
end

function M.enable()
  started = true
  config.values.auto_start = true
  restart_helper()
end

function M.disable()
  started = false
  helper.stop()
  fallback.stop()
end

return M
