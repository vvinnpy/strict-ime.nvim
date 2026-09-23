local M = {}

local mode_map = {
  n = "norm",
  no = "norm",
  nov = "norm",
  noV = "norm",
  niI = "norm",
  niR = "norm",
  niV = "norm",
  -- Terminal-Normal keeps the terminal job alive; input methods belong to the
  -- terminal application (tig, less, etc.), not to Neovim normal mode.
  nt = "term",
  ntT = "term",
  rm = "norm",
  ["r?"] = "norm",

  v = "vis",
  vs = "vis",
  V = "vis",
  Vs = "vis",
  ["\22"] = "vis",

  s = "sel",
  S = "sel",
  ["\19"] = "sel",

  i = "ins",
  ic = "ins",
  ix = "ins",
  R = "ins",
  Rc = "ins",
  Rx = "ins",
  Rv = "ins",
  Rvc = "ins",
  Rvx = "ins",

  c = "cmd",
  cv = "cmd",
  ce = "cmd",

  t = "term",
  l = "lang",
}

function M.key(mode)
  local code = mode or vim.api.nvim_get_mode().mode
  if code == "c" then
    local cmdtype = vim.fn.getcmdtype()
    if cmdtype == "/" or cmdtype == "?" then
      return "search"
    end
  end
  return mode_map[code] or "norm"
end

function M.current()
  local code = vim.api.nvim_get_mode().mode
  return {
    mode = code,
    key = M.key(code),
  }
end

return M
