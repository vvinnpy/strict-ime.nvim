local M = {}

local config = require("strict-ime.config")
local helper = require("strict-ime.helper")
local fallback = require("strict-ime.fallback")
local mode = require("strict-ime.mode")
local install = require("strict-ime.install")

local started = false
local shutting_down = false
local previous_key
local previous_strict
local prior = {}

local function notify(message, level)
  vim.notify("strict-ime: " .. message, level or vim.log.levels.INFO)
end

local function current_imname()
  local result = vim.system({ "fcitx5-remote", "-n" }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  local name = vim.trim(result.stdout or "")
  return name ~= "" and name or nil
end

local function ensure_fcitx5()
  if not config.values.autostart_fcitx5 or vim.fn.executable("fcitx5") ~= 1 then
    return
  end

  local running = vim.system({ "pgrep", "-x", "fcitx5" }, { text = true }):wait()
  if running.code ~= 0 then
    vim.system({ "fcitx5", "-d" }, { text = true }):wait()
  end
end

local function is_strict(mode_key, target)
  return config.values.strict_modes[mode_key] == true and target == config.values.english
end

local function target_imname(mode_key)
  if config.values.strict_modes[mode_key] == true then
    return config.values.english
  end
  if config.values.remember_prior and prior[mode_key] then
    return prior[mode_key]
  end
  return config.values.imname[mode_key]
end

local function set_imname(imname, force)
  if not imname then
    return
  end
  if helper.active() then
    helper.set_im(imname, force)
  else
    fallback.set_im(imname, force)
  end
end

local function sync_mode(force)
  if not started then
    return
  end

  local current = mode.current()
  local mode_key = current.key
  if not mode_key then
    return
  end

  if config.values.remember_prior and previous_key and previous_key ~= mode_key then
    local current_im = current_imname()
    if current_im then
      prior[previous_key] = current_im
    end
  end

  local target = target_imname(mode_key)
  local strict = is_strict(mode_key, target)

  if strict ~= previous_strict then
    if helper.active() then
      helper.set_strict(strict)
    else
      fallback.set_strict(strict)
    end
    previous_strict = strict
  elseif strict and not helper.active() then
    fallback.set_strict(true)
  end

  if not strict then
    set_imname(target, force or previous_key ~= mode_key)
  end

  if config.values.remember_prior and target then
    prior[mode_key] = target
  end
  previous_key = mode_key
end

local function restart_helper()
  ensure_fcitx5()
  helper.stop()
  if helper.start() then
    fallback.stop()
    previous_strict = nil
    helper.set_strict(target_imname(previous_key or mode.key()) == config.values.english)
  else
    fallback.set_strict(true)
  end
  sync_mode(true)
end

local function setup_commands()
  local function add_command(name, callback, opts)
    opts = opts or {}
    opts.force = true
    vim.api.nvim_create_user_command(name, callback, opts)
  end

  local function cmd_status()
    local current = mode.current()
    notify(string.format(
      "mode=%s key=%s helper=%s strict=%s",
      current.mode,
      current.key,
      tostring(helper.active()),
      tostring(previous_strict)
    ))
  end

  local function cmd_set_name(opts)
    local mode_key = mode.current().key
    set_imname(opts.args, true)
    if config.values.remember_prior then
      prior[mode_key] = opts.args
    end
  end

  local function cmd_geneious()
    sync_mode(true)
  end

  local function cmd_on_mode_changed()
    sync_mode(false)
  end

  local function cmd_set_prior(opts)
    local imname = opts.fargs[1]
    local mode_key = opts.fargs[2] or mode.current().key
    prior[mode_key] = imname
    notify(string.format("prior[%s]=%s", mode_key, imname))
  end

  local function cmd_get_imname(opts)
    local mode_key = opts.args ~= "" and opts.args or mode.current().key
    notify(tostring(target_imname(mode_key)))
  end

  local function cmd_get_imnames()
    local result = {}
    for _, key in ipairs({ "norm", "ins", "cmd", "vis", "sel", "opr", "term", "lang" }) do
      result[key] = target_imname(key)
    end
    notify(vim.inspect(result))
  end

  add_command("StrictImeInstallHelper", function()
    install.install()
  end, { desc = "Install the strict-ime D-Bus helper" })
  add_command("StrictImeRestart", function()
    restart_helper()
    notify("restarted")
  end, { desc = "Restart the strict-ime helper" })
  add_command("StrictImeStatus", cmd_status, { desc = "Show strict-ime status" })
  add_command("StrictImeSetName", cmd_set_name, { nargs = 1, desc = "Force the input method for the current mode" })
  add_command("StrictImeGeneious", cmd_geneious, { desc = "Apply the configured input method for the current mode" })
  add_command("StrictImeOnModeChanged", cmd_on_mode_changed, { desc = "Compatibility entry point for ModeChanged" })
  add_command("StrictImeSetPrior", cmd_set_prior, { nargs = "+", desc = "Set the remembered input method for a mode" })
  add_command("StrictImeGetImname", cmd_get_imname, { nargs = "?", desc = "Get the input method for a mode" })
  add_command("StrictImeGetImnames", cmd_get_imnames, { desc = "Get input methods for all modes" })

  if config.values.legacy_commands then
    add_command("Fcitx5", function()
      notify("compatibility commands: Fcitx5SetName, Fcitx5Geneious, Fcitx5SetPrior, Fcitx5GetImname, Fcitx5GetImnames")
    end, { desc = "Show strict-ime compatibility help" })
    add_command("Fcitx5SetName", cmd_set_name, { nargs = 1, desc = "Compatibility alias for StrictImeSetName" })
    add_command("Fcitx5Geneious", cmd_geneious, { desc = "Compatibility alias for StrictImeGeneious" })
    add_command("Fcitx5OnModeChanged", cmd_on_mode_changed, { desc = "Compatibility alias for StrictImeOnModeChanged" })
    add_command("Fcitx5SetPrior", cmd_set_prior, { nargs = "+", desc = "Compatibility alias for StrictImeSetPrior" })
    add_command("Fcitx5GetImname", cmd_get_imname, { nargs = "?", desc = "Compatibility alias for StrictImeGetImname" })
    add_command("Fcitx5GetImnames", cmd_get_imnames, { desc = "Compatibility alias for StrictImeGetImnames" })
  end
end


M.Fcitx5SetName = function(imname)
  set_imname(imname, true)
  if config.values.remember_prior then
    prior[mode.current().key] = imname
  end
end

M.Fcitx5Geneious = function()
  sync_mode(true)
end

M.Fcitx5OnModeChanged = function()
  sync_mode(false)
end

M.Fcitx5SetPrior = function(imname, mode_key)
  prior[mode_key or mode.current().key] = imname
end

M.Fcitx5GetImname = function(mode_key)
  return target_imname(mode_key or mode.current().key)
end

M.Fcitx5GetImnames = function()
  local result = {}
  for _, key in ipairs({ "norm", "ins", "cmd", "vis", "sel", "opr", "term", "lang" }) do
    result[key] = target_imname(key)
  end
  return result
end

function M.setup(opts)
  config.setup(opts)
  prior = {}
  previous_key = nil
  previous_strict = nil
  shutting_down = false
  fallback.stop()
  helper.stop()

  local group = vim.api.nvim_create_augroup("StrictImeNvim", { clear = true })
  if config.values.define_autocmd then
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = group,
      pattern = "*:*",
      callback = function()
        vim.schedule(function()
          sync_mode(false)
        end)
      end,
    })
  end
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      shutting_down = true
      helper.stop()
      fallback.stop()
    end,
  })

  setup_commands()
  started = true
  if config.values.auto_start and not shutting_down then
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
