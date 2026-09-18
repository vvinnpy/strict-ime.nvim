local M = {}

M.defaults = {
  english = "keyboard-us",
  insert = "pinyin",
  imname = {
    norm = nil,
    ins = nil,
    cmd = nil,
    search = nil,
    vis = nil,
    sel = nil,
    opr = nil,
    term = nil,
    lang = nil,
  },
  strict_modes = {
    norm = true,
    opr = true,
    vis = true,
    sel = true,
    cmd = false,
    search = false,
  },
  manage_cmdline = false,
  tmux_focus_events = false,
  remember_prior = true,
  autostart_fcitx5 = true,
  define_autocmd = true,
  legacy_commands = true,
  poll_interval = 200,
  auto_start = true,
  helper = {
    enabled = true,
    path = nil,
    repo = "vvinnpy/strict-ime.nvim",
  },
}

M.values = vim.deepcopy(M.defaults)

local function normalize(values)
  values.imname = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults.imname), values.imname or {})

  for _, key in ipairs({ "norm", "cmd", "search", "vis", "sel", "opr", "lang" }) do
    if values.imname[key] == nil then
      values.imname[key] = values.english
    end
  end
  if values.imname.ins == nil then
    values.imname.ins = values.insert
  end

  return values
end

function M.setup(opts)
  M.values = normalize(vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {}))
  return M.values
end

function M.get_imname(mode_key)
  return M.values.imname[mode_key]
end

return M
