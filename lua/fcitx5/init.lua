local strict_ime = require("strict-ime")

local M = {}

function M.setup(opts)
  return strict_ime.setup(opts)
end

function M.Fcitx5SetName(imname)
  return strict_ime.Fcitx5SetName(imname)
end

function M.Fcitx5Geneious()
  return strict_ime.Fcitx5Geneious()
end

function M.Fcitx5OnModeChanged()
  return strict_ime.Fcitx5OnModeChanged()
end

function M.Fcitx5SetPrior(imname, mode_key)
  return strict_ime.Fcitx5SetPrior(imname, mode_key)
end

function M.Fcitx5GetImname(mode_key)
  return strict_ime.Fcitx5GetImname(mode_key)
end

function M.Fcitx5GetImnames()
  return strict_ime.Fcitx5GetImnames()
end

return M
