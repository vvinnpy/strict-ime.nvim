local M = {}

local function helper_arch()
  local machine = vim.uv.os_uname().machine
  if machine == "x86_64" or machine == "amd64" then
    return "amd64"
  end
  if machine == "aarch64" or machine == "arm64" then
    return "arm64"
  end
  return nil
end

function M.target_path()
  local config = require("strict-ime.config").values
  if config.helper.path and config.helper.path ~= "" then
    return vim.fn.expand(config.helper.path)
  end
  local arch = helper_arch()
  if not arch then
    return nil
  end
  return vim.fn.stdpath("data") .. "/strict-ime/strict-ime-helper-linux-" .. arch
end

function M.install()
  local config = require("strict-ime.config").values
  local arch = helper_arch()
  if not arch then
    vim.notify("strict-ime: unsupported architecture", vim.log.levels.ERROR)
    return false
  end

  local target = M.target_path()
  local url = string.format(
    "https://github.com/%s/releases/latest/download/strict-ime-helper-linux-%s",
    config.helper.repo,
    arch
  )
  local tmp = target .. ".download"
  vim.fn.mkdir(vim.fn.fnamemodify(target, ":h"), "p")

  local result = vim.system({ "curl", "-fL", url, "-o", tmp }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("strict-ime: helper download failed: " .. (result.stderr or ""), vim.log.levels.WARN)
    return false
  end

  vim.uv.fs_chmod(tmp, 493)
  vim.uv.fs_rename(tmp, target)
  vim.notify("strict-ime: helper installed at " .. target, vim.log.levels.INFO)
  return true
end

return M
