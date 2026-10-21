local M = {}

local config = require("strict-ime.config")
local helper = require("strict-ime.helper")

local BUS_NAME = "org.fcitx.Fcitx5"
local OBJECT_PATH = "/rime"
local INTERFACE = "org.fcitx.Fcitx.Rime1"
local MIN_HELPER_VERSION = { 0, 6, 0 }

local helper_supported

local function parse_version(output)
  local major, minor, patch = (output or ""):match("(%d+)%.(%d+)%.(%d+)")
  if not major then
    return nil
  end
  return { tonumber(major), tonumber(minor), tonumber(patch) }
end

local function version_at_least(actual, expected)
  for i = 1, 3 do
    if actual[i] ~= expected[i] then
      return actual[i] > expected[i]
    end
  end
  return true
end

local function read_ascii_mode()
  local result
  if vim.fn.executable("gdbus") == 1 then
    result = vim.system({
      "gdbus",
      "call",
      "--session",
      "--dest",
      BUS_NAME,
      "--object-path",
      OBJECT_PATH,
      "--method",
      INTERFACE .. ".IsAsciiMode",
    }, { text = true }):wait()
  elseif vim.fn.executable("busctl") == 1 then
    result = vim.system({
      "busctl",
      "--user",
      "call",
      BUS_NAME,
      OBJECT_PATH,
      INTERFACE,
      "IsAsciiMode",
    }, { text = true }):wait()
  else
    return nil
  end

  if result.code ~= 0 then
    return nil
  end

  local output = vim.trim(result.stdout or "")
  if output:match("true") then
    return true
  end
  if output:match("false") then
    return false
  end
  return nil
end

function M.helper_supported()
  if helper_supported ~= nil then
    return helper_supported
  end

  local path = helper.path()
  if not path then
    helper_supported = false
    return false
  end

  local result = vim.system({ path, "--version" }, { text = true }):wait()
  if result.code ~= 0 then
    helper_supported = false
    return false
  end

  local actual = parse_version(result.stdout)
  helper_supported = actual ~= nil and version_at_least(actual, MIN_HELPER_VERSION)
  return helper_supported
end

function M.native_enabled()
  if config.values.rime_native == false then
    return false
  end
  if config.values.imname.ins ~= "rime" then
    return false
  end
  if not helper.active() then
    return false
  end
  return M.helper_supported()
end

function M.encode_state(state)
  return {
    imname = "rime",
    active = true,
    -- "active" keeps its existing meaning in this plugin: active input means
    -- Chinese. Rime expresses the same state through ascii_mode.
    ascii = state.active == false,
  }
end

function M.decode_state(imname)
  if imname ~= "rime" then
    return nil
  end
  local ascii = read_ascii_mode()
  if ascii == nil then
    return nil
  end
  return { imname = imname, active = not ascii }
end

function M.reset()
  helper_supported = nil
end

return M
