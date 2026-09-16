local M = {}

local uv = vim.uv or vim.loop
local config = require("strict-ime.config")
local install = require("strict-ime.install")

local stdin, stdout, stderr
local handle
local active = false
local last_strict = nil
local last_input_key = nil

local function helper_path()
  local configured = config.values.helper.path
  if configured and configured ~= "" then
    local path = vim.fn.expand(configured)
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  local target = install.target_path()
  if target and vim.fn.executable(target) == 1 then
    return target
  end

  local path = vim.fn.exepath("strict-ime-helper")
  if path and path ~= "" then
    return path
  end

  return nil
end

local function write(payload)
  if not active or not stdin then
    return false
  end
  stdin:write(vim.json.encode(payload) .. "\n")
  return true
end

local function close_pipes()
  for _, pipe in ipairs({ stdin, stdout, stderr }) do
    if pipe and not pipe:is_closing() then
      pipe:close()
    end
  end
  stdin, stdout, stderr = nil, nil, nil
end

function M.start()
  if active then
    return true
  end
  if not config.values.helper.enabled then
    return false
  end

  local path = helper_path()
  if not path then
    return false
  end

  stdin = uv.new_pipe(false)
  stdout = uv.new_pipe(false)
  stderr = uv.new_pipe(false)

  local ok, spawn_handle = pcall(uv.spawn, path, {
    args = { "-interval", tostring(config.values.poll_interval) },
    stdio = { stdin, stdout, stderr },
  }, function()
    active = false
    handle = nil
    close_pipes()
  end)

  if not ok or not spawn_handle then
    close_pipes()
    return false
  end

  handle = spawn_handle
  active = true
  last_strict = nil
  last_input_key = nil
  return true
end

function M.stop()
  active = false
  if stdin and not stdin:is_closing() then
    pcall(function()
      stdin:write('{"cmd":"quit"}\n')
    end)
  end
  if handle and not handle:is_closing() then
    handle:close()
  end
  handle = nil
  close_pipes()
  last_strict = nil
  last_input_key = nil
end

function M.active()
  return active
end

function M.set_strict(strict)
  if last_strict == strict and active then
    return
  end
  last_strict = strict
  write({ cmd = "set_strict", value = strict })
end

local function normalize_state(state)
  if type(state) == "table" then
    return {
      imname = state.imname,
      active = state.active ~= false,
    }
  end
  return { imname = state, active = true }
end

function M.set_input(state, force)
  state = normalize_state(state)
  if not state.imname then
    return
  end

  local key = state.imname .. ":" .. tostring(state.active)
  if not force and last_input_key == key then
    return
  end

  last_input_key = key
  write({ cmd = "set_state", value = state })
end

function M.set_im(imname, force)
  M.set_input({ imname = imname, active = true }, force)
end

return M
