local uv = vim.uv or vim.loop

local M = {}
local config = require("strict-ime.config")
local timer
local strict = false
local last_input_key = nil

local function run(args)
  vim.system({ "fcitx5-remote", unpack(args) }, { text = true }, function() end)
end

function M.set_strict(value)
  strict = value
  if not timer then
    timer = uv.new_timer()
  end
  if value then
    timer:start(0, config.values.poll_interval, vim.schedule_wrap(function()
      if strict then
        run({ "-c" })
      end
    end))
  else
    timer:stop()
  end
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

  vim.system({ "fcitx5-remote", "-s", state.imname }, { text = true }, function(result)
    if result.code == 0 and not state.active then
      vim.system({ "fcitx5-remote", "-c" }, { text = true }, function() end)
    end
  end)
end

function M.set_im(imname, force)
  M.set_input({ imname = imname, active = true }, force)
end

function M.stop()
  strict = false
  if timer then
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
    timer = nil
  end
end

return M
