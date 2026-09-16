local M = {}

M.defaults = {
  english = "keyboard-us",
  insert = "pinyin",
  poll_interval = 200,
  auto_start = true,
  helper = {
    enabled = true,
    path = nil,
    repo = "vvinnpy/strict-ime.nvim",
  },
}

M.values = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.values
end

return M
