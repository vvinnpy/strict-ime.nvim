local M = {}

local insert_like = {
  i = true,
  ic = true,
  ix = true,
  R = true,
  Rc = true,
  Rx = true,
  Rv = true,
  Rvc = true,
  Rvx = true,
  t = true,
}

function M.current()
  local mode = vim.api.nvim_get_mode().mode
  return {
    mode = mode,
    strict = not insert_like[mode],
  }
end

return M
