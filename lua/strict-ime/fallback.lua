local uv = vim.uv or vim.loop

local M = {}
local config = require("strict-ime.config")
local timer
local strict = false
local last_im = nil

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

function M.set_im(imname, force)
  if not imname or (not force and last_im == imname) then
    return
  end
  last_im = imname
  run({ "-s", imname })
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
